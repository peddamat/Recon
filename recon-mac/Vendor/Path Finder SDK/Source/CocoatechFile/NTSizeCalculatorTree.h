//
//  NTSizeCalculatorTree.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTSizeCalculatorTreeRoot, NTFolderWatcher, NTSizeCalculatorTreeOperation;

@interface NTSizeCalculatorTree : NSObject
{
	NTSizeCalculatorTreeRoot* treeRoot;
	// the queue to do the treaded operations
	NSOperationQueue* queue;
	NTSizeCalculatorTreeOperation* operation;
	
	// watching the whole volume
	NTFolderWatcher* watcher;
	
	// folders and messages waiting to be added to tree and processed
	NSMutableDictionary* pendingFolders;
	NSMutableDictionary* pendingRemoveFolders;
	NSMutableDictionary* pendingRefreshMessages;
	
	BOOL sentDelayedPerformPendingRefresh;
	BOOL sentDelayedPerformPendingFolders;

	NSMutableArray* pendingOperations;
}
@property (retain) NTSizeCalculatorTreeRoot* treeRoot;
@property (retain) NSOperationQueue* queue;
@property (retain) NTSizeCalculatorTreeOperation* operation;
@property (retain) NTFolderWatcher* watcher;
@property (retain) NSMutableDictionary* pendingFolders;
@property (retain) NSMutableDictionary* pendingRemoveFolders;
@property (retain) NSMutableDictionary* pendingRefreshMessages;
@property (retain) NSMutableArray* pendingOperations;
@property (assign) BOOL sentDelayedPerformPendingRefresh;
@property (assign) BOOL sentDelayedPerformPendingFolders;

+ (NTSizeCalculatorTree*)treeForVolume:(NTVolume*)theVolume;

// called when rearranging tree, moving children to a new parent
- (void)addFolders:(NSArray*)theFolders;
- (void)removeFolders:(NSArray*)theFolders;

// converts /Volumes/myDisk/folder to /folder
+ (NSString*)treePathForPath:(NSString*)thePath;

// debug only
- (void)debugTreeNodeForFolder:(NTFileDesc*)folder;

@end

