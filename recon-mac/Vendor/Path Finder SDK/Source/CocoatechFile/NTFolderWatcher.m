//
//  NTFolderWatcher.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTFolderWatcher.h"
#import "NTVolumeNotificationMgr.h"
#import "NTFSEventMessage.h"
#include <sys/stat.h>
#import "NTVolumeMgrState.h"
#import "NTFolderWatcherManager.h"
#import "NTVolume.h"

@interface NTFolderWatcher ()
@property (retain) NTFileDesc* desc;
@end

@interface NTFolderWatcher (Private)
- (void)startWatchingOnMainThread:(NTPointerObject*)thePointerObject;
- (void)startWatching;

- (NSString *)createRelativePath;

- (FSEventStreamRef)streamRef;
- (void)setStreamRef:(FSEventStreamRef)theStreamRef;
@end

static void fsevents_callback(FSEventStreamRef streamRef,
							  void *clientCallBackInfo, 
							  int numEvents,
							  NSArray *eventPaths, 
							  const FSEventStreamEventFlags *eventMasks, 
							  const uint64_t *eventIDs);

@implementation NTFolderWatcher

@synthesize watchSubfolders;
@synthesize latency;
@synthesize relativePath;
@synthesize delegate, desc;
@synthesize devicePath, volumeIdentifier, dictionaryKey, deviceWatcher, caseSensitive;

+ (NTFolderWatcher*)watcher:(id<NTFolderWatcherDelegateProtocol>)theDelegate
					 folder:(NTFileDesc*)theFolder 
			watchSubfolders:(BOOL)theWatchSubfolders
					latency:(float)theLatency;
{
	// return nil if folder is readOnly, locked etc.  Network volumes could be writable by others, so allow that
	if (![theFolder isComputer] && [theFolder isReadOnly] && [theFolder isLocalFileSystem])
		return nil;
	
	// make sure volume is still mounted
	NSString* theDevicePath = [[[theFolder volume] mountPoint] path];
	if (!theDevicePath && ![theFolder isComputer])
		return nil;
	
	NTFolderWatcher* result = [[self alloc] init];
		
	[result setDesc:theFolder];
	result.devicePath = theDevicePath;
	result.relativePath = [result createRelativePath];
	result.delegate = theDelegate;
	result.watchSubfolders = theWatchSubfolders;
	result.caseSensitive = [[theFolder volume] caseSensitive];
	
	if (theLatency < .1)
		theLatency = .1;
	
	result.latency = theLatency;
	
	[result startWatching];
	
	if (![theFolder isComputer])
	{		
		// we use diskIDString since we want to handle volume renames, network volumes don't allow renaming
		// network volumes don't have a diskIDString, so if nil, use the mountPoint path as a URL
		if ([theFolder isLocalFileSystem])
			result.volumeIdentifier = [[theFolder volume] diskIDString];
		else
			result.volumeIdentifier = [[NSURL fileURLWithPath:result.devicePath] absoluteString];
	}
	
	result.dictionaryKey = [theFolder dictionaryKey];
	[[NTFolderWatcherManager sharedInstance] addWatcher:result volumeIdentifier:result.volumeIdentifier dictionaryKey:result.dictionaryKey];
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{	
	[[NTFolderWatcherManager sharedInstance] removeWatcher:self volumeIdentifier:self.volumeIdentifier dictionaryKey:self.dictionaryKey];

	if (self.delegate)
		[NSException raise:@"must call clearDelegate" format:@"%@", NSStringFromClass([self class])];
	
    [self setDesc:nil];
	[self setStreamRef:nil];
	self.relativePath = nil;
	self.devicePath = nil;
	self.volumeIdentifier = nil;
	self.dictionaryKey = nil;
	
	[super dealloc];
}

- (void)invalidate;
{
	[self setStreamRef:nil];  // close the open file
	self.delegate = nil;
}

- (void)clearDelegate;
{
	self.delegate = nil;
}

//---------------------------------------------------------- 
//  folder 
//---------------------------------------------------------- 
- (NTFileDesc *)folder
{
	return self.desc; 
}

+ (void)manuallyRefreshDirectory:(NTFileDesc*)directory;
{
	if ([directory isComputer])
		[NTVolumeMgrState incrementBuild];  // must increment build number to create new NTFileDescs, otherwise you'll get the same as previous list
	
	if (directory)
	{		
		NSArray* messages = [NSArray arrayWithObject:[NTFSEventMessage message:[directory path] rescanSubdirectories:NO]];
		
		NSArray* watchers = [[NTFolderWatcherManager sharedInstance] watchersForDesc:directory];
		for (NTFolderWatcher *watcher in watchers)
			[watcher notifyDelegate:messages];
	}
}

@end

@implementation NTFolderWatcher (NTFolderWatcherManagerAccess)

- (void)notifyDelegate:(NSArray*)theMessages;
{	
	[[self delegate] folderWatcher:self folder:self.desc messages:theMessages];
}

@end

@implementation NTFolderWatcher (Private)

//---------------------------------------------------------- 
//  createRelativePath 
//---------------------------------------------------------- 
- (NSString *)createRelativePath;
{
	NSString* path = [self.desc path];
	
	NSString* mountPath = [[[self.desc volume] mountPoint] path];
	
	if (mountPath.length > 1) // not "/"
		path = [path stringByDeletingPrefix:mountPath caseSensitive:self.caseSensitive];
	
	// get rid of "/"
	if (path.length)
		path = [path substringFromIndex:1]; // skip "/"
	
	// to avoid problems in comparing paths, we don't want to store paths with trailing a "/"
	if ([path length] > 1)
	{
		if ([path characterAtIndex:([path length]-1)] == '/')
			path = [path substringToIndex:([path length]-1)];
	}
	
	return path; 
}

- (void)startWatching;
{	
	if ([self.desc isComputer])
	{
		if (self.watchSubfolders)
			; // NSLog(@"-[%@ %@] watchSubfolders not supported on computer level", [self className], NSStringFromSelector(_cmd));
	}
	else	
	{
		// create streamRef in thread to avoid slow network drives from hanging UI
		[NSThread detachNewThreadSelector:@selector(startWatchingThread) toTarget:self withObject:nil];
	}
}

// must be called on main thread so that we get the main threads runloop
- (void)startWatchingOnMainThread:(NTPointerObject*)thePointerObject;
{	
	[self setStreamRef:[thePointerObject pointer]];

	if ([self streamRef])
	{
		FSEventStreamScheduleWithRunLoop([self streamRef], CFRunLoopGetMain(), kCFRunLoopDefaultMode);
		
		Boolean startedOK = FSEventStreamStart([self streamRef]);
		if (!startedOK)
			NSLog(@"-[%@ %@] FSEventStreamStart failed", [self className], NSStringFromSelector(_cmd));
	}	
}

//---------------------------------------------------------- 
//  streamRef 
//---------------------------------------------------------- 
- (FSEventStreamRef)streamRef
{
	return mStreamRef;
}

- (void)setStreamRef:(FSEventStreamRef)theStreamRef
{	
	if (mStreamRef)
	{
		FSEventStreamStop(mStreamRef);
		FSEventStreamInvalidate(mStreamRef);
		FSEventStreamRelease(mStreamRef);
		mStreamRef = NULL;
	}
	
	mStreamRef = theStreamRef;	
}

@end

@implementation NTFolderWatcher (Thread)

- (FSEventStreamRef)FSEventStreamCreate;
{
	struct stat st;
	if (lstat([self.desc fileSystemPath], &st) == 0)
	{
		dev_t deviceToWatch = st.st_dev;
		
		FSEventStreamRef streamRef = NULL;
		CFMutableArrayRef cfArray;
		FSEventStreamContext  context = {0, self, NULL, NULL, NULL};
		
		cfArray = CFArrayCreateMutable(kCFAllocatorDefault, 1, &kCFTypeArrayCallBacks);	
		
		if ([self.desc isLocalFileSystem])
		{
			// Local volumes can be renamed, so we watch the device rather than a path.
			// device watching doesn't work with network volumes, so we use the FSEventStreamCreate for those
			self.deviceWatcher = YES;
			
			CFArraySetValueAtIndex(cfArray, 0, (CFStringRef)[self relativePath]);

			streamRef = FSEventStreamCreateRelativeToDevice(kCFAllocatorDefault,
															(FSEventStreamCallback)&fsevents_callback,
															&context,
															deviceToWatch,
															cfArray,
															kFSEventStreamEventIdSinceNow, // since when
															self.latency, // latency
															kFSEventStreamCreateFlagUseCFTypes);
		}
		else
		{
			CFArraySetValueAtIndex(cfArray, 0, (CFStringRef)[self.desc path]);

			// network volumes need this
			streamRef = FSEventStreamCreate(kCFAllocatorDefault,
											(FSEventStreamCallback)&fsevents_callback,
											&context,
											cfArray,
											kFSEventStreamEventIdSinceNow, // since when
											self.latency, // latency
											kFSEventStreamCreateFlagUseCFTypes);
		}
		
		CFRelease(cfArray);
		if (streamRef)
			return streamRef;
	}
	
	NSLog(@"-[%@ %@] FSEventStreamCreate failed: %@", [self className], NSStringFromSelector(_cmd), [self.desc path]);
	
	return nil;
}

// create streamRef in thread to avoid slow network drives from hanging UI
- (void)startWatchingThread;
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	{
		FSEventStreamRef streamRef = [self FSEventStreamCreate];
		
		[self performSelectorOnMainThread:@selector(startWatchingOnMainThread:) withObject:[NTPointerObject object:streamRef] waitUntilDone:NO];
	}
	[pool release];
}

@end

static void fsevents_callback(FSEventStreamRef streamRef,
							  void *clientCallBackInfo, 
							  int numEvents,
							  NSArray *eventPaths, 
							  const FSEventStreamEventFlags *eventMasks, 
							  const uint64_t *eventIDs)
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	{
		NTFolderWatcher* watcher = (NTFolderWatcher*)clientCallBackInfo;
		NSString* thePath;
		int cnt=0;
		int i;
		NSMutableArray* theMessages = [NSMutableArray array];
		
		for (thePath in eventPaths)
		{			
			i = cnt++;
			
			// to avoid problems in comparing paths, we don't want to store paths with trailing a "/"
			if ([thePath length] > 1)
			{
				// FSEventStreamCreate returns full paths, detect a full path and convert to relative path
				if (!watcher.deviceWatcher)
				{
					if ([thePath hasPrefix:watcher.devicePath caseSensitive:watcher.caseSensitive])
					{
						thePath = [thePath stringByDeletingPrefix:watcher.devicePath caseSensitive:watcher.caseSensitive];
						
						// also get rid of the '/' for example /test/ should be test/
						if ([thePath length])
						{
							if ([thePath characterAtIndex:0] == '/')
								thePath = [thePath substringFromIndex:1];
						}
					}
				}

				// remove trailing /
				if ([thePath length] > 1)
				{
					if ([thePath characterAtIndex:([thePath length]-1)] == '/')
						thePath = [thePath substringToIndex:([thePath length]-1)];
				}
			}
			
			BOOL rescanSubdirectories = NO;
			if (eventMasks[i] & kFSEventStreamEventFlagMustScanSubDirs) 
				rescanSubdirectories = YES;
			else if (eventMasks[i] & kFSEventStreamEventFlagUserDropped) 
				rescanSubdirectories = YES;
			else if (eventMasks[i] & kFSEventStreamEventFlagKernelDropped) 
				rescanSubdirectories = YES;
			
			if (![watcher watchSubfolders])
			{
				if ([thePath isEqualToString:[watcher relativePath] caseSensitive:watcher.caseSensitive])
					[theMessages addObject:[NTFSEventMessage message:thePath rescanSubdirectories:rescanSubdirectories]];
				else
				{
					// also notify on changes one level down from folder
					// this will refresh a parent folder so it can refresh to display new mod dates for example, or adding/removing arrows in list view
					thePath = [thePath stringByDeletingLastPathComponent];
					if ([thePath isEqualToString:[watcher relativePath] caseSensitive:watcher.caseSensitive])
						[theMessages addObject:[NTFSEventMessage message:thePath rescanSubdirectories:rescanSubdirectories]];
				}
			}
			else
				[theMessages addObject:[NTFSEventMessage message:thePath rescanSubdirectories:rescanSubdirectories]];
		}
		
		if (theMessages.count)
			[watcher notifyDelegate:theMessages];
	}
	[pool release];
	pool = nil;
}



