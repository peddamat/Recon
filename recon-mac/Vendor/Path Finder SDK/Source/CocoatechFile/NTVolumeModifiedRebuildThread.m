//
//  NTVolumeModifiedRebuildThread.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 8/2/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import "NTVolumeModifiedRebuildThread.h"
#import "NTDefaultDirectory.h"
#import "NTVolumeMgr.h"
#import "NTFolderWatcher.h"

@implementation NTVolumeModifiedRebuildThread

@synthesize volumeWatchers;

+ (NTThreadRunner*)thread:(id<NTThreadRunnerDelegateProtocol>)delegate;
{
    NTVolumeModifiedRebuildThread* param = [[[NTVolumeModifiedRebuildThread alloc] init] autorelease];
		
	return [NTThreadRunner thread:param
						 priority:.5
						 delegate:delegate];	
}

- (void)dealloc
{
	self.volumeWatchers = nil;

    [super dealloc];
}

@end

@implementation NTVolumeModifiedRebuildThread (Thread)

- (BOOL)doThreadProc;
{		
	NSMutableArray* watchers = [NSMutableArray array];
	NSArray* volumes = [[[NTDefaultDirectory sharedInstance] computer] directoryContents:YES resolveIfAlias:NO];
	
	for (NTFileDesc* volume in volumes)
	{
		NTFolderWatcher* theWatcher = [NTFolderWatcher watcher:(id<NTFolderWatcherDelegateProtocol>)[self delegate] folder:volume watchSubfolders:YES latency:2];
		
		if (theWatcher)
			[watchers addObject:theWatcher];
	}
	
	self.volumeWatchers = [NSArray arrayWithArray:watchers];
	
	return (![[self helper] killed]);
}

@end
