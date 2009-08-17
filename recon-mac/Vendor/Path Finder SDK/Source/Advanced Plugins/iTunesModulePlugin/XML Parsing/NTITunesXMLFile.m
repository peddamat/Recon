//
//  NTITunesXMLFile.m
//  iLike
//
//  Created by Steve Gehrman on 12/10/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTITunesXMLFile.h"
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/event.h>
#import "NTITunesDataModel.h"

// =================================================================================================
// packages up the kqueue event information and passes it to a selector on the main thread

@interface NTKQueueEvent: NSObject
{
	int mv_fd;
	unsigned int mv_fflags;
	unsigned int mv_uniqueID;
}

+ (NTKQueueEvent*)eventWithFD:(int)fd fflags:(unsigned int)fflags uniqueID:(unsigned int)uniqueID;

- (int)fd;
- (unsigned int)uniqueID;
- (unsigned int)fflags;

@end

// =================================================================================================
// this structure is used to send information to our kQueue thread through our pipe
// this is a method of ensuring thread safety

typedef enum
{
	kKillThread_KQueueMessage=1,
	
	kAddFD_KQueueMessage,
	kRemoveFD_KQueueMessage
	
} NTITunesXMLFileMessageType;

typedef struct 
{
	NTITunesXMLFileMessageType messageType;
	int fd;	
	unsigned int uniqueID;	
} NTITunesXMLFileMessage;

// =================================================================================================

@interface NTITunesXMLFile (Private)
- (void)notifyObserverWithResponse:(NTKQueueEvent*)response;
- (NSString*)fflagsToString:(unsigned int)fflags;

- (NSDate*)updateModificationDate;

- (int)KQueueFD;
- (void)setKQueueFD:(int)theKQueueFD;

- (void)addToKQueue:(int)fd;
- (void)removeFromKQueue:(int)fd;

- (BOOL)sentFolderModifiedNotification;
- (void)setSentFolderModifiedNotification:(BOOL)flag;

- (NSPipe *)pipe;
- (void)setPipe:(NSPipe *)thePipe;

- (NSDate *)modificationDate;
- (void)setModificationDate:(NSDate *)theModificationDate;

- (int)FD;
- (void)setFD:(int)theFD;

- (void)subscribe;
- (void)unsubscribe;
@end

@interface NTITunesXMLFile (hidden)
- (void)setDatabasePath:(NSString *)theDatabasePath;
@end

@implementation NTITunesXMLFile

@synthesize delegate;

+ (NTITunesXMLFile*)file:(id<NTITunesXMLFileDelegateProtocol>)theDelegate;
{
	NTITunesXMLFile* result = [[NTITunesXMLFile alloc] init];
	
	[result setDelegate:theDelegate];
	
	return [result autorelease];
}

- (id)init;
{
	self = [super init];
	
	[self updateModificationDate]; // must get initial mod date so we know when it changes
	[self subscribe];

	return self;
}

- (void)dealloc;
{	
	if ([self delegate])
		NSLog(@"-[%@ %@] missing clearDelegate", [self className], NSStringFromSelector(_cmd));
	
    [self setModificationDate:nil];

	[self setDatabasePath:nil];
    [self setPipe:nil];
	
	[super dealloc];
}

- (void)clearDelegate;
{
	[self setDelegate:nil];
	
	[self unsubscribe];
}

- (void)kill;
{
	NTITunesXMLFileMessage message;
	message.messageType = kKillThread_KQueueMessage;
	message.fd = 0;
	
	[[[self pipe] fileHandleForWriting] writeData:[NSData dataWithBytes:&message length:sizeof(message)]];	
}

//---------------------------------------------------------- 
//  databasePath 
//---------------------------------------------------------- 
- (NSString *)databasePath
{
	if (!mDatabasePath)
	{
		[[NSUserDefaults standardUserDefaults] addSuiteNamed: @"com.apple.iApps"];
		NSArray *xmlArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"iTunesRecentDatabases"];
		
		// db: the simple way to find iTunes library .xml files - but it's not in com.apple.iTunes as you might expect
		[[NSUserDefaults standardUserDefaults] removeSuiteNamed: @"com.apple.iApps"];
		
		NSURL* url = [NSURL URLWithString:[xmlArray objectAtIndex: 0]];
		
		[self setDatabasePath:[url path]];
	}
	
    return mDatabasePath; 
}

- (void)setDatabasePath:(NSString *)theDatabasePath
{
    if (mDatabasePath != theDatabasePath)
    {
        [mDatabasePath release];
        mDatabasePath = [theDatabasePath retain];
    }
}

@end

@implementation NTITunesXMLFile (ThreadProc)

- (BOOL)handleThreadMessage:(NSFileHandle*)reader;
{
	BOOL threadKilled=NO;
	NTITunesXMLFileMessage message;
	int resultCode;
	struct kevent change;
	
	// constants used for adding, deleting files to the kqueue
	static const u_int addFlags = (EV_ADD | EV_CLEAR);
	static const u_int deleteFlags = (EV_DELETE | EV_CLEAR);
	static const u_int fflags = (NOTE_WRITE); 
	
	NSData* data = [reader readDataOfLength:sizeof(message)];
	if (data && ([data length] == sizeof(message)))
	{		
		[data getBytes:&message];
		
		switch (message.messageType)
		{
			case kKillThread_KQueueMessage:
				threadKilled = YES;
				break;
			case kAddFD_KQueueMessage:
			{
				EV_SET(&change, message.fd, EVFILT_VNODE, addFlags, fflags, 0, (void*)message.uniqueID);
				
				resultCode = kevent([self KQueueFD], &change, 1, NULL, 0, NULL);
				if (resultCode != 0)
					NSLog(@"kevent add: %d, errno:%d", resultCode, errno);
			}	
				break;
			case kRemoveFD_KQueueMessage:
			{
				EV_SET(&change, message.fd, EVFILT_VNODE, deleteFlags, fflags, 0, (void*)message.uniqueID);
				
				resultCode = kevent([self KQueueFD], &change, 1, NULL, 0, NULL);
				if (resultCode != 0)
				{
					int errorCode = errno;
					
					// if (errorCode == ENOENT)
					//   ; // got this, ejecting a disk?
					
					if ((errorCode != EBADF) && (errorCode != ENOENT)) // means bad fd, which is because the file was probably closed by the subscription which is OK
						NSLog(@"kevent delete: %d, errno:%d", resultCode, errno);								
				}
			}
				break;
		}
	}
	
	return threadKilled;
}

- (void)threadWorker:(NSFileHandle*)reader
{
	struct kevent event;
	struct kevent change;
	NSAutoreleasePool* pool;
	
	// register to receive messages through the pipe
	EV_SET(&change, [reader fileDescriptor], EVFILT_READ, EV_ADD, 0, 0, 0);
	kevent([self KQueueFD], &change, 1, NULL, 0, NULL);
	
	BOOL threadKilled = NO;
	while (!threadKilled)
	{
		pool = [[NSAutoreleasePool alloc] init];
		
		NS_DURING;
		
		// wait for events
		int n = kevent([self KQueueFD], NULL, 0, &event, 1, NULL);
		if( n > 0 )
		{
			switch (event.filter)
			{
				case EVFILT_READ: 
				{
					// A message, handle it
					threadKilled = [self handleThreadMessage:reader];
				}
					break;
					
				case EVFILT_VNODE:
				{					
					// NSLog(@"kevent OK %@", [self fflagsToString:event.fflags]);
					
					unsigned int uniqueID = (unsigned int)event.udata;  // ident is the fd for EVFILT_VNODE
					int fd = (int)event.ident;  // ident is the fd for EVFILT_VNODE

					// file had changed: notify on main thread
					[self performSelectorOnMainThread:@selector(notifyObserverWithResponse:)
										   withObject:[NTKQueueEvent eventWithFD:fd fflags:event.fflags uniqueID:uniqueID] 
										waitUntilDone:NO];
				}
					break;
			}
		}
		
		NS_HANDLER 
			NSLog(@"Error in NTITunesXMLFile: %@", localException);		
		NS_ENDHANDLER;
		
		[pool release];
	}
}

@end

@implementation NTITunesXMLFile (Private)

//---------------------------------------------------------- 
//  modificationDate 
//---------------------------------------------------------- 
- (NSDate *)modificationDate
{
    return mModificationDate; 
}

- (void)setModificationDate:(NSDate *)theModificationDate
{
    if (mModificationDate != theModificationDate)
    {
        [mModificationDate release];
        mModificationDate = [theModificationDate retain];
    }
}

- (void)subscribe;
{
	NSString* folderPath = [[self databasePath] stringByDeletingLastPathComponent];
	int fd = open([folderPath fileSystemRepresentation], O_EVTONLY, 0);
	if (fd != -1)
	{
		[self setFD:fd];
		
		[self addToKQueue:fd];
	
		// start up thread
		[NSThread detachNewThreadSelector:@selector(threadWorker:) toTarget:self withObject:[[self pipe] fileHandleForReading]];
	}
}

- (void)unsubscribe;
{
	if ([self FD])
	{
		[self removeFromKQueue:[self FD]];
		[self kill];
			
		[self setFD:0];
		[self setKQueueFD:0];
	}
}

- (void)addToKQueue:(int)fd;
{
	NTITunesXMLFileMessage message;
	message.messageType = kAddFD_KQueueMessage;
	message.fd = fd;
	message.uniqueID = 0;
	
	[[[self pipe] fileHandleForWriting] writeData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)removeFromKQueue:(int)fd;
{
	NTITunesXMLFileMessage message;
	message.messageType = kRemoveFD_KQueueMessage;
	message.fd = fd;
	message.uniqueID = 0;
	
	[[[self pipe] fileHandleForWriting] writeData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

// called on main thread
- (void)notifyObserverWithResponse:(NTKQueueEvent*)response
{				
	// cancel previous one if running
	if ([self sentFolderModifiedNotification])
	{
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(folderWasModified) object:nil];

		[self setSentFolderModifiedNotification:NO];
	}
	
	if (![self sentFolderModifiedNotification])
	{
		[self setSentFolderModifiedNotification:YES];
		
		[self performSelector:@selector(folderWasModified) withObject:nil afterDelay:5];
	}
}

- (void)folderWasModified;
{
	[self setSentFolderModifiedNotification:NO];

	BOOL notify = NO;
	
	// get old date, update mod date, compare old with new
	NSDate *previousModDate = [self updateModificationDate];
	if (previousModDate)
	{		
		// folder was modified, but we need to check if the file was modified
		NSComparisonResult result = [[self modificationDate] compare:previousModDate];
		if (result != NSOrderedSame)
			notify = YES;
	}
	
	if (notify)
		[[self delegate] iTunesXMLFile_wasUpdated:self];
}

- (NSDate*)updateModificationDate;
{
	NSDate *result = [[[self modificationDate] retain] autorelease];
	
	NSDictionary* dict = [[NSFileManager defaultManager] attributesOfItemAtPath:[self databasePath] error:nil];
	[self setModificationDate:[dict fileModificationDate]];
	
	return result;
}

//---------------------------------------------------------- 
//  sentFolderModifiedNotification 
//---------------------------------------------------------- 
- (BOOL)sentFolderModifiedNotification
{
    return mSentFolderModifiedNotification;
}

- (void)setSentFolderModifiedNotification:(BOOL)flag
{
    mSentFolderModifiedNotification = flag;
}

- (NSString*)fflagsToString:(unsigned int)fflags;
{
	NSMutableString* result = [NSMutableString string];
	
	if( (fflags & NOTE_RENAME) == NOTE_RENAME )
		[result appendString:@":NOTE_RENAME"];
	if( (fflags & NOTE_WRITE) == NOTE_WRITE )
		[result appendString:@":NOTE_WRITE"];
	if( (fflags & NOTE_DELETE) == NOTE_DELETE )
		[result appendString:@":NOTE_DELETE"];
	if( (fflags & NOTE_ATTRIB) == NOTE_ATTRIB )
		[result appendString:@":NOTE_ATTRIB"];
	if( (fflags & NOTE_EXTEND) == NOTE_EXTEND )
		[result appendString:@":NOTE_EXTEND"];
	if( (fflags & NOTE_REVOKE) == NOTE_REVOKE )
		[result appendString:@":NOTE_REVOKE"];
	if( (fflags & NOTE_LINK) == NOTE_LINK)
		[result appendString:@":NOTE_LINK"];
	
	return result;
}

//---------------------------------------------------------- 
//  KQueueFD 
//---------------------------------------------------------- 
- (int)KQueueFD
{
	if (!mKQueueFD)
		[self setKQueueFD:kqueue()];

    return mKQueueFD;
}

- (void)setKQueueFD:(int)theKQueueFD
{
	if (mKQueueFD)
		close(mKQueueFD);
	
    mKQueueFD = theKQueueFD;
}

//---------------------------------------------------------- 
//  pipe 
//---------------------------------------------------------- 
- (NSPipe *)pipe
{
	if (!mPipe)
		[self setPipe:[[[NSPipe alloc] init] autorelease]];
	
    return mPipe; 
}

- (void)setPipe:(NSPipe *)thePipe
{
    if (mPipe != thePipe)
    {
        [mPipe release];
        mPipe = [thePipe retain];
    }
}

//---------------------------------------------------------- 
//  FD 
//---------------------------------------------------------- 
- (int)FD
{
    return mFD;
}

- (void)setFD:(int)theFD
{
	if (mFD)
		close(mFD);

    mFD = theFD;
}

@end

// =================================================================================================
// =================================================================================================

@implementation NTKQueueEvent

- (id)initWithFD:(int)fd fflags:(unsigned int)fflags uniqueID:(unsigned int)uniqueID;
{
	self = [super init];
	
	mv_fd = fd;
	mv_fflags = fflags;	
	mv_uniqueID = uniqueID;
	
	return self;	
}

+ (NTKQueueEvent*)eventWithFD:(int)fd fflags:(unsigned int)fflags uniqueID:(unsigned int)uniqueID;
{
	NTKQueueEvent* result = [[NTKQueueEvent alloc] initWithFD:fd fflags:fflags uniqueID:uniqueID];
	
	return [result autorelease];
}

- (unsigned int)fflags
{
	return mv_fflags;
}

- (int)fd
{
	return mv_fd;
}

- (unsigned int)uniqueID
{
	return mv_uniqueID;
}

@end
