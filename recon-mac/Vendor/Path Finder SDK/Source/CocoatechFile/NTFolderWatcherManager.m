//
//  NTFolderWatcherManager.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 8/21/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import "NTFolderWatcherManager.h"
#import "NTFolderWatcher.h"
#import "NTVolume.h"
#import "NTVolumeNotificationMgr.h"
#import "NTFSEventMessage.h"
#import "NTDefaultDirectory.h"

@interface NTFolderWatcherManager (Private)
- (void)ejectingVolume:(NSString*)volumeIdentifier;
- (void)setupUnmountCallback;
@end

@implementation NTFolderWatcherManager

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

static DADissenterRef unmountCallback( DADiskRef disk, void * context );

@synthesize activeWatchersByVolume, activeWatchersByFolder, session;

- (id)init;
{
	self = [super init];
	
	self.activeWatchersByVolume = [NSMutableDictionary dictionary];
	self.activeWatchersByFolder = [NSMutableDictionary dictionary];
	
	[self setupUnmountCallback];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(volumeListChangedNotification:)
												 name:kNTVolumeMgrVolumeListHasChangedNotification
											   object:[NTVolumeNotificationMgr sharedInstance]];
	
	return self;
}

- (void)dealloc;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	self.activeWatchersByVolume = nil;
	self.activeWatchersByFolder = nil;
	
	if (self.session)
	{
		DAApprovalSessionUnscheduleFromRunLoop(self.session, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
		
		CFRelease(self.session);
		self.session = nil;
	}
	
	[super dealloc];
}

- (void)addWatcher:(NTFolderWatcher*)theWatcher volumeIdentifier:(NSString*)theVolumeIdentifier dictionaryKey:(NSString*)theDictionaryKey;
{	
	NTProxy* proxy = [NTProxy proxyWithObject:theWatcher];
	
	@synchronized(self) {
		// ## save in activeWatchersByVolume
		if (theVolumeIdentifier)  // if nil, it's the computer
		{
			NSMutableArray* watcherArray = [self.activeWatchersByVolume objectForKey:theVolumeIdentifier];
			if (!watcherArray)
			{
				watcherArray = [NSMutableArray array];
				[self.activeWatchersByVolume setObject:watcherArray forKey:theVolumeIdentifier];
			}
			[watcherArray addObject:proxy];
		}
		
		// ## save in activeWatchersByFolder
		if (theDictionaryKey)
		{
			NSMutableArray* watcherArray = [self.activeWatchersByFolder objectForKey:theDictionaryKey];
			if (!watcherArray)
			{
				watcherArray = [NSMutableArray array];
				[self.activeWatchersByFolder setObject:watcherArray forKey:theDictionaryKey];
			}
			[watcherArray addObject:proxy];
		}
	}
}

- (void)removeWatcher:(NTFolderWatcher*)theWatcher volumeIdentifier:(NSString*)theVolumeIdentifier dictionaryKey:(NSString*)theDictionaryKey;
{	
	@synchronized(self) {
		// ## remove from activeWatchersByVolume
		if (theVolumeIdentifier)  // if nil, it's the computer
		{
			NSMutableArray* watcherArray = [self.activeWatchersByVolume objectForKey:theVolumeIdentifier];
			NSUInteger removeIndex = NSNotFound;
			NSUInteger index = 0;
			for (NTProxy* proxy in watcherArray)
			{
				if (theWatcher == proxy.object)
				{
					removeIndex = index;
					break;
				}
				
				index++;
			}
			
			if (removeIndex != NSNotFound)
				[watcherArray removeObjectAtIndex:removeIndex];
			else
				NSLog(@"failed to find watcher");
		}
		
		// ## save in activeWatchersByFolder
		if (theDictionaryKey)
		{
			NSMutableArray* watcherArray = [self.activeWatchersByFolder objectForKey:theDictionaryKey];
			NSUInteger removeIndex = NSNotFound;
			NSUInteger index = 0;
			for (NTProxy* proxy in watcherArray)
			{
				if (theWatcher == proxy.object)
				{
					removeIndex = index;
					break;
				}
				
				index++;
			}
			
			if (removeIndex != NSNotFound)
				[watcherArray removeObjectAtIndex:removeIndex];
			else
				NSLog(@"failed to find watcher");			
		}
	}	
}

- (NSArray*)watchersForDesc:(NTFileDesc*)theDesc;
{
	NSArray* result = nil;
	NSString* dictionaryKey = [theDesc dictionaryKey];
	
	@synchronized(self) {
		result = [NSArray arrayWithArray:[self.activeWatchersByFolder objectForKey:dictionaryKey]];
	}
	
	// get watchers from proxies
	result = [result arrayByPerformingSelector:@selector(object)];
	
	return result;
}

- (NSArray*)watchersForDiskID:(NSString*)theVolumeIdentifier;
{
	NSArray* result = nil;
	
	@synchronized(self) {
		result = [NSArray arrayWithArray:[self.activeWatchersByVolume objectForKey:theVolumeIdentifier]];
	}
	
	// get watchers from proxies
	result = [result arrayByPerformingSelector:@selector(object)];
	
	return result;
}

@end

@implementation NTFolderWatcherManager (Private)

- (void)setupUnmountCallback;
{
	if ([NSThread isMainThread])
	{
		self.session = DAApprovalSessionCreate(NULL);
		DARegisterDiskUnmountApprovalCallback(self.session, NULL, unmountCallback, (void*)self);  
		DAApprovalSessionScheduleWithRunLoop(self.session, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
	}
	else
		[self performSelectorOnMainThread:@selector(setupUnmountCallback)];
}

- (void)ejectingVolume:(NSString*)volumeIdentifier;
{		
	// invalidate all watchers on this volume so it will eject with out a -47 error
	NSArray* watcherArray = [self watchersForDiskID:volumeIdentifier];
	
	for (NTFolderWatcher* watcher in watcherArray)
		[watcher invalidate];
}

@end

@implementation NTFolderWatcherManager (Notifications)

// volume list changes
- (void)volumeListChangedNotification:(NSNotification*)notification;
{	
	// refresh computer watchers
	NSArray* messages = [NSArray arrayWithObject:[NTFSEventMessage message:@"" rescanSubdirectories:NO]];
	
	NSArray* watchers = [[NTFolderWatcherManager sharedInstance] watchersForDesc:[[NTDefaultDirectory sharedInstance] computer]];
	for (NTFolderWatcher *watcher in watchers)
		[watcher notifyDelegate:messages];
}

@end

static DADissenterRef unmountCallback( DADiskRef disk, void * context )
{	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	{
		NTFolderWatcherManager* mgr = (NTFolderWatcherManager*)context;

		CFDictionaryRef ref = DADiskCopyDescription(disk);
		if (ref)
		{			
			NSDictionary *dict = [NSDictionary dictionaryWithDictionary:(NSDictionary*)ref];
			
			NSString* volumeIdentifier = [dict objectForKey:(NSString*)kDADiskDescriptionMediaBSDNameKey];
			if (!volumeIdentifier)  // must be network volume, use URL as string
				volumeIdentifier = [[dict objectForKey:(NSString*)kDADiskDescriptionVolumePathKey] absoluteString];
			
			if (volumeIdentifier)
				[mgr ejectingVolume:volumeIdentifier];

			CFRelease(ref);
		}
	}
	[pool release];
	pool = nil;
	
	return nil;
}
