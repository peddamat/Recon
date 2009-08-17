//
//  NTVolumeModifiedWatcher.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/7/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import "NTVolumeModifiedWatcher.h"
#import "NTFolderWatcher.h"
#import "NTDefaultDirectory.h"
#import "NTVolume.h"
#import "NTVolumeMgrState.h"
#import "NTVolumeSpec.h"
#import "NTVolumeMgr.h"
#import "NTVolumeModifiedWatcherThread.h"
#import "NTVolumeModifiedRebuildThread.h"

@interface NTVolumeModifiedWatcher (Notifications) <NTFolderWatcherDelegateProtocol>
@end

@interface NTVolumeModifiedWatcher (Private) 
- (void)clearVolumeWatchers;
- (void)rebuildVolumeWatchers;
@end

@interface NTVolumeModifiedWatcher (Protocols) <NTThreadRunnerDelegateProtocol>
@end

@implementation NTVolumeModifiedWatcher

@synthesize computerWatcher, rebuildThread, threadRunner, volumeWatchers,volumeFreespaceCache, rebuildingVolumeWatchers, rescanningVolumes;

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

- (id)init;
{
	self = [super init];
	
	self.computerWatcher = [NTFolderWatcher watcher:self folder:[[NTDefaultDirectory sharedInstance] computer] watchSubfolders:NO latency:0];

	// call once to prime it up
	[self setThreadRunner:[NTVolumeModifiedWatcherThread thread:self previousCache:nil]];
	
	[self rebuildVolumeWatchers];
	
	return self;
}

- (void)dealloc;
{
	[self.computerWatcher clearDelegate];
	self.computerWatcher = nil;
	self.volumeFreespaceCache = nil;
	
	self.threadRunner = nil;
	self.rebuildThread = nil;
	
	[self clearVolumeWatchers];
	
	[super dealloc];
}

@end

@implementation NTVolumeModifiedWatcher (Private) 

- (void)clearVolumeWatchers;
{
	[self.volumeWatchers makeObjectsPerformSelector:@selector(clearDelegate)];
	self.volumeWatchers = nil;
}

- (void)rebuildVolumeWatchers;
{
	if (!self.rebuildingVolumeWatchers)
	{
		self.rebuildingVolumeWatchers = YES;
		
		[self performDelayedSelector:@selector(rebuildVolumeWatchersAfterDelay) withObject:nil delay:4];
	}
}

- (void)rebuildVolumeWatchersAfterDelay;
{	
	[self setRebuildThread:[NTVolumeModifiedRebuildThread thread:self]];
}

- (void)rescanVolumes;
{
	if (!self.rescanningVolumes)
	{
		self.rescanningVolumes = YES;
		
		[self performDelayedSelector:@selector(rescanVolumesAfterDelay) withObject:nil delay:8];
	}
}

- (void)rescanVolumesAfterDelay;
{
	self.rescanningVolumes = NO;
		
	[self setThreadRunner:[NTVolumeModifiedWatcherThread thread:self previousCache:[NSDictionary dictionaryWithDictionary:self.volumeFreespaceCache]]];
}

// override to clear delegate
- (void)setThreadRunner:(NTThreadRunner*)theThreadRunner;
{
	@synchronized(self)	{
		if (theThreadRunner != threadRunner)
		{
			[threadRunner clearDelegate];
			
			[threadRunner release];
			threadRunner = [theThreadRunner retain];
		}
	}
}

// override to clear delegate
- (void)setRebuildThread:(NTThreadRunner*)theThread;
{
	@synchronized(self)	{
		if (theThread != rebuildThread)
		{
			[rebuildThread clearDelegate];
			
			[rebuildThread release];
			rebuildThread = [theThread retain];
		}
	}
}

@end

@implementation NTVolumeModifiedWatcher (Notifications) 

// <NTFolderWatcherDelegateProtocol>

- (void)folderWatcher:(NTFolderWatcher*)theWatcher
			   folder:(NTFileDesc*)theFolder
			 messages:(NSArray*)theMessages;
{
	// make sure we are watching all current volumes
	if (theWatcher == self.computerWatcher)
	{
		// volume added or removed
		[self rebuildVolumeWatchers];
	}
	else // one of the volumeWatchers
	{
		// volume was modified, send out notification
		[self rescanVolumes];
	}
}

@end

@implementation NTVolumeModifiedWatcher (Protocols)

// NTThreadRunnerDelegateProtocol
- (void)threadRunner_complete:(NTThreadRunner*)theThreadRunner;
{
	if (theThreadRunner == [self threadRunner])
	{
		NTVolumeModifiedWatcherThread* param = (NTVolumeModifiedWatcherThread*)[theThreadRunner param];
		
		// first time run just to build the cache, so don't do anything if nil first time
		if (self.volumeFreespaceCache)
		{
			if ([[param changedVolumeSpecs] count])
			{
				[NTFolderWatcher manuallyRefreshDirectory:[[NTDefaultDirectory sharedInstance] computer]];
								
				NSMutableArray* volumeRefNums = [NSMutableArray array];
				for (NTVolumeSpec* spec in [param changedVolumeSpecs])
					[volumeRefNums addObject:[NSNumber numberWithInt:[spec volumeRefNum]]];
				
				// send notification to refresh freespace display in 
			 	[[NSNotificationCenter defaultCenter] postNotificationName:kNTVolumeFreespaceModifiedNotification
																	object:nil 
																  userInfo:[NSDictionary dictionaryWithObject:volumeRefNums forKey:@"volumeRefNums"]];
			}
		}
		
		// save cache for next call
		self.volumeFreespaceCache = [param freespaceCache];
		
		[self setThreadRunner:nil];
	}
	else if (theThreadRunner == self.rebuildThread)
	{
		self.rebuildingVolumeWatchers = NO;
		
		NTVolumeModifiedRebuildThread* param = (NTVolumeModifiedRebuildThread*)[theThreadRunner param];
		
		[self clearVolumeWatchers];
		self.volumeWatchers = param.volumeWatchers;
		
		self.rebuildThread = nil;
	}		
}

@end

