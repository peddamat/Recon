//
//  NTFolderWatcher.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFolderWatcher, NTFileDesc;

@protocol NTFolderWatcherDelegateProtocol <NSObject>
- (void)folderWatcher:(NTFolderWatcher*)theWatcher
			   folder:(NTFileDesc*)theFolder
			  messages:(NSArray*)theMessages;
@end

@interface NTFolderWatcher : NSObject
{
	id<NTFolderWatcherDelegateProtocol> delegate;
	NTFileDesc* desc;
	NSString* relativePath;
	NSString* devicePath;
	NSString* volumeIdentifier;
	NSString* dictionaryKey;
	
	BOOL watchSubfolders;
	float latency;
	BOOL deviceWatcher;
	BOOL caseSensitive;
	
	FSEventStreamRef mStreamRef;
}

@property (assign) id<NTFolderWatcherDelegateProtocol> delegate;  // not retained
@property (retain) NSString* relativePath;
@property (retain) NSString* devicePath;
@property (retain) NSString* volumeIdentifier;
@property (assign) BOOL watchSubfolders;
@property (assign) BOOL deviceWatcher;
@property (assign) float latency;
@property (assign) BOOL caseSensitive;
@property (retain) NSString* dictionaryKey;

+ (NTFolderWatcher*)watcher:(id<NTFolderWatcherDelegateProtocol>)theDelegate
					 folder:(NTFileDesc*)theFolder 
			watchSubfolders:(BOOL)theWatchSubfolders
					latency:(float)latency;

- (void)clearDelegate;

- (NTFileDesc *)folder;
- (void)invalidate;

+ (void)manuallyRefreshDirectory:(NTFileDesc*)directory;

@end

@interface NTFolderWatcher (NTFolderWatcherManagerAccess)
- (void)notifyDelegate:(NSArray*)theMessages;
@end
