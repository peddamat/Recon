//
//  NTFolderWatcherManager.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 8/21/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFolderWatcher;

@interface NTFolderWatcherManager : NTSingletonObject
{
	NSMutableDictionary *activeWatchersByVolume;  // watchers per volume
	NSMutableDictionary *activeWatchersByFolder;  // watchers by folder
	
	DAApprovalSessionRef session;
}

@property (retain, nonatomic) NSMutableDictionary *activeWatchersByVolume;
@property (retain, nonatomic) NSMutableDictionary *activeWatchersByFolder;
@property (assign, nonatomic) DAApprovalSessionRef session;

- (void)addWatcher:(NTFolderWatcher*)theWatcher volumeIdentifier:(NSString*)theVolumeIdentifier dictionaryKey:(NSString*)theDictionaryKey;
- (void)removeWatcher:(NTFolderWatcher*)theWatcher volumeIdentifier:(NSString*)theVolumeIdentifier dictionaryKey:(NSString*)theDictionaryKey;

- (NSArray*)watchersForDesc:(NTFileDesc*)theDesc;
- (NSArray*)watchersForDiskID:(NSString*)theDiskIDString;
@end
