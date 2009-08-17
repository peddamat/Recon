//
//  NTVolumeModifiedWatcher.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/7/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFolderWatcher;

// manually refreshes computer list if more than .5 K 
#define kNTVolumeFreespaceModifiedNotification @"NTVolumeFreespaceModifiedNotification"

@interface NTVolumeModifiedWatcher : NTSingletonObject 
{
	NTFolderWatcher* computerWatcher;

	NSArray *volumeWatchers;
	NTThreadRunner* rebuildThread;

	BOOL rebuildingVolumeWatchers;
	BOOL rescanningVolumes;
	
	NSDictionary* volumeFreespaceCache;
	NTThreadRunner* threadRunner;
}

@property (retain) NTFolderWatcher* computerWatcher;
@property (retain) NSArray *volumeWatchers;
@property (retain) NTThreadRunner* rebuildThread;
@property (retain) NSDictionary* volumeFreespaceCache;
@property (assign) BOOL rebuildingVolumeWatchers;
@property (assign) BOOL rescanningVolumes;
@property (retain) NTThreadRunner* threadRunner;

@end
