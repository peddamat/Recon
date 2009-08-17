//
//  NTSizeCalculatorTreeRoot.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTSizeCalculatorTreeNode;

@interface NTSizeCalculatorTreeRoot : NSObject
{
	// the tree plus some dictionaries to quickly find the folder in the tree
	NTSizeCalculatorTreeNode* rootNode;
	NSMutableDictionary* nodeFolderMap; // quick access to nodes in the tree
	NSMutableDictionary* nodePathMap; // quick access to nodes in the tree	
	NSMutableDictionary* folders; // folders that have active NTSizeCalculator objects (the ones we care about updating)
}

@property (retain) NSMutableDictionary* folders;
@property (retain) NTSizeCalculatorTreeNode* rootNode;
@property (retain) NSMutableDictionary* nodeFolderMap;
@property (retain) NSMutableDictionary* nodePathMap;

+ (NTSizeCalculatorTreeRoot*)treeRootForVolume:(NTVolume*)theVolume;

// called from operation from a thread
- (NTSizeCalculatorTreeNode*)addFolderToTree:(NTFileDesc*)theFolder;
- (NTSizeCalculatorTreeNode*)addPathToTree:(NSString*)thePath;

// accessing nodes by path used in the fsevent handling to invalidate
- (NTSizeCalculatorTreeNode*)nodeOrParentForPath:(NSString*)thePath;
- (NTSizeCalculatorTreeNode*)parentForPath:(NSString*)thePath;

- (void)debugTreeNodeForFolder:(NTFileDesc*)theFolder;

@end

// stuff to remove deleted and readd invalid nodes
// called before a calc when verifying a subtree
// returns nodes removed or removed and readded
@interface NTSizeCalculatorTreeRoot (TreeRepair)
- (NSArray*)removeNodesAndChildren:(NSArray*)theNodes removeFolders:(BOOL)removeFolders;
@end