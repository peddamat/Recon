//
//  NTKQueueMonitor.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 9/5/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NTKQueueMonitor.h"
#import "NTKQueueSubscription.h"
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/event.h>
#import "NTFileEnvironment.h"

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
	
} NTKQueueMonitorMessageType;

typedef struct 
{
	NTKQueueMonitorMessageType messageType;
	int fd;	
	unsigned int uniqueID;	
} NTKQueueMonitorMessage;

// =================================================================================================

@interface NTKQueueMonitor (Private)
- (void)addToKQueue:(NTKQueueSubscription*)subscription;
- (void)removeFromKQueue:(NTKQueueSubscription*)subscription;
- (void)notifyObserverWithResponse:(NTKQueueEvent*)response;
- (NSString*)fflagsToString:(unsigned int)fflags;
@end

@implementation NTKQueueMonitor

NTSINGLETONOBJECT_STORAGE

- (id)init;
{
	self = [super init];

	if (self)
	{
		mv_kqueueFD = kqueue();
		
		mv_pipe = [[NSPipe pipe] retain];
		
		[NSThread detachNewThreadSelector:@selector(threadWorker:) toTarget:self withObject:[mv_pipe fileHandleForReading]];
	}
	
	return self;
}

- (void)dealloc;
{
	close(mv_kqueueFD);
	[mv_pipe release];

	[super dealloc];
}

// subclassed to add to our kqueue
- (void)add:(NTFSSubscription*)subscription;
{
	[self addToKQueue:(NTKQueueSubscription*)subscription];
	
	[super  add:subscription];
}

// subclassed to remove from our kqueue
- (void)remove:(NTFSSubscription*)subscription;
{
	[self removeFromKQueue:(NTKQueueSubscription*)subscription];
	
	[super  remove:subscription];
}

- (void)kill;
{
	NTKQueueMonitorMessage message;
	message.messageType = kKillThread_KQueueMessage;
	message.fd = 0;
	
	[[mv_pipe fileHandleForWriting] writeData:[NSData dataWithBytes:&message length:sizeof(message)]];	
}

@end

@implementation NTKQueueMonitor (ThreadProc)

- (BOOL)handleThreadMessage:(NSFileHandle*)reader;
{
	BOOL threadKilled=NO;
	NTKQueueMonitorMessage message;
	int resultCode;
	struct kevent change;

	// constants used for adding, deleting files to the kqueue
	static const u_int addFlags = (EV_ADD | EV_CLEAR);
	static const u_int deleteFlags = (EV_DELETE | EV_CLEAR);
	static const u_int fflags = (NOTE_DELETE |  NOTE_WRITE | NOTE_EXTEND | NOTE_ATTRIB | NOTE_RENAME | NOTE_REVOKE);  // not includeing NOTE_LINK
	
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
				
				resultCode = kevent(mv_kqueueFD, &change, 1, NULL, 0, NULL);
				if (resultCode != 0)
					; // NSLog(@"kevent add: %d, errno:%d", resultCode, errno);
			}	
				break;
			case kRemoveFD_KQueueMessage:
			{
				EV_SET(&change, message.fd, EVFILT_VNODE, deleteFlags, fflags, 0, (void*)message.uniqueID);
				
				resultCode = kevent(mv_kqueueFD, &change, 1, NULL, 0, NULL);
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
	kevent(mv_kqueueFD, &change, 1, NULL, 0, NULL);
	
	BOOL threadKilled = NO;
	while (!threadKilled)
	{
		pool = [[NSAutoreleasePool alloc] init];
		
		NS_DURING;
		
		// wait for events
		int n = kevent(mv_kqueueFD, NULL, 0, &event, 1, NULL);
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
					BOOL notify=YES;
					int fd = (int)event.ident;  // ident is the fd for EVFILT_VNODE

					// we don't care about access date changes, so check the date, and if it is "now" skip it
					// check for == not just the bit set, don't want to block a combination event
					if (event.fflags == NOTE_ATTRIB)
					{
						struct stat sb;
												
						// use lstat and return NO if it returns non 0
						if (fstat(fd, &sb) == 0)
						{
							NTTime *left = [NTTime time]; 
							NTTime* right = [NTTime timeWithTimespec:&(sb.st_atimespec)];
														
							if ([left compareSeconds:right] == NSOrderedSame)
							{
								if (FENV(debugFSWatcher))
									NSLog(@"blocked: %@", [self fflagsToString:event.fflags]);

								notify = NO;
							}
							else
							{
								if (FENV(debugFSWatcher))
									NSLog(@"%@", [NSString stringWithFormat:@"time: %@, access:%@", [[left date] description], [[right date] description]]);
							}
						}
					}
					
					if (notify)
					{
						if (FENV(debugFSWatcher))
							NSLog(@"kevent OK %@", [self fflagsToString:event.fflags]);

						unsigned int uniqueID = (unsigned int)event.udata;  // ident is the fd for EVFILT_VNODE
						
						// file had changed: notify on main thread
						[self performSelectorOnMainThread:@selector(notifyObserverWithResponse:)
											   withObject:[NTKQueueEvent eventWithFD:fd fflags:event.fflags uniqueID:uniqueID]];
					}
				}
					break;
			}
		}
		
		NS_HANDLER;
			NSLog(@"Error in NTKQueueMonitor: %@", localException);		
		NS_ENDHANDLER;
		
		[pool release];
	}
}

@end

@implementation NTKQueueMonitor (Private)

- (void)addToKQueue:(NTKQueueSubscription*)subscription;
{
	NTKQueueMonitorMessage message;
	message.messageType = kAddFD_KQueueMessage;
	message.fd = [subscription fd];
	message.uniqueID = [[subscription uniqueID] unsignedIntValue];

	[[mv_pipe fileHandleForWriting] writeData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)removeFromKQueue:(NTKQueueSubscription*)subscription;
{
	NTKQueueMonitorMessage message;
	message.messageType = kRemoveFD_KQueueMessage;
	message.fd = [subscription fd];
	message.uniqueID = [[subscription uniqueID] unsignedIntValue];
	
	[[mv_pipe fileHandleForWriting] writeData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

// called on main thread
- (void)notifyObserverWithResponse:(NTKQueueEvent*)response
{				
	[self subscriptionWithUniqueIDWasModified:[response uniqueID]];
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
