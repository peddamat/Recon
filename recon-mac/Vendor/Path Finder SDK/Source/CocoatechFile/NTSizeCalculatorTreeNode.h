//
//  NTSizeCalculatorTreeNode.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFSSize;

@interface NTSizeCalculatorTreeNode : NSObject
{
	NTSizeCalculatorTreeNode* parent;
	NSMutableDictionary* children;
	
	NSString* treePath;
	NTFileDesc* desc;

	NTFSSize* size;
	
	BOOL needToRecalc;  // we were marked dirty by a refresh, must recalc out contents
	BOOL needToRecalcChildren; // one or more children was set to dirty, need to recalc them first to get correct size
	BOOL needToVerify; // a parent was marked dirty, could have renamed, moved or deleted children.  Children in tree below need to verify their place in the tree
}

@property (assign) NTSizeCalculatorTreeNode* parent;  // not retained to avoid retain loop
@property (retain) NSMutableDictionary* children; // we do our own thread safely when modifying
@property (retain) NSString* treePath;
@property (retain) NTFileDesc* desc;
@property (retain) NTFSSize* size;
@property (assign) BOOL needToRecalc;
@property (assign) BOOL needToRecalcChildren;
@property (assign) BOOL needToVerify;

// dynamic, a function of the content and subfolders
@property (readonly, assign) BOOL sizeIsValid;

+ (NTSizeCalculatorTreeNode*)rootNode:(NTFileDesc*)theFolder;
 
- (NTSizeCalculatorTreeNode*)addChildWithTreePath:(NSString*)theTreePath folder:(NTFileDesc*)theFolder;

- (void)markDirty:(BOOL)mustRescanChildren;

// used when shuffling children around on a tree reshuffle
- (void)addChildren:(NSArray*)children;
- (void)removeChildren:(NSArray*)children;
- (void)addChild:(NTSizeCalculatorTreeNode*)theChild;
- (void)removeChild:(NTSizeCalculatorTreeNode*)theChild;

// returns nodes that were recalced (so that we can send out all notifications even if children were calced)
- (NSArray*)calculateSize:(NSOperation*)operation;

// validate node and children marked needToVerify (call before doing a calc)
// returns a dictionary of "deleted" and "invalid" nodes
// the caller will try to add invalid nodes (and their children) back in the tree
// the caller can notify client of delete nodes (and their children)
- (NSDictionary*)verify;

@end
