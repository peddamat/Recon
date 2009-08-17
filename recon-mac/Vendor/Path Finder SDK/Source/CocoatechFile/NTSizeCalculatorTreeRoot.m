//
//  NTSizeCalculatorTreeRoot.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTSizeCalculatorTreeRoot.h"
#import "NTSizeCalculatorTreeNode.h"
#import "NTSizeCalculatorTree.h"

@interface NTSizeCalculatorTreeRoot (Private)
- (NTSizeCalculatorTreeNode*)doAddPathToTree:(NSString*)thePath folder:(NTFileDesc*)theFolder;
@end

@implementation NTSizeCalculatorTreeRoot

@synthesize folders;
@synthesize rootNode;
@synthesize nodePathMap;
@synthesize nodeFolderMap;

+ (NTSizeCalculatorTreeRoot*)treeRootForVolume:(NTVolume*)theVolume;
{
	NTSizeCalculatorTreeRoot* result = nil;

	// ejecting a volume could make this nil, must check
	NTFileDesc* mountPoint = [theVolume mountPoint];
	if (mountPoint)
	{
		result = [[NTSizeCalculatorTreeRoot alloc] init];
		
		result.folders = [NSMutableDictionary dictionary];
		result.rootNode = [NTSizeCalculatorTreeNode rootNode:mountPoint];
		result.nodePathMap = [NSMutableDictionary dictionaryWithObject:result.rootNode forKey:[result.rootNode treePath]];  // relative path
		result.nodeFolderMap = [NSMutableDictionary dictionaryWithObject:result.rootNode forKey:[[result.rootNode desc] dictionaryKey]];
	}
	
	return [result autorelease];
}

- (void)dealloc;
{
	self.folders = nil;
	self.rootNode = nil;
	self.nodePathMap = nil;
	self.nodeFolderMap = nil;
	
	[super dealloc];
}

- (NTSizeCalculatorTreeNode*)addFolderToTree:(NTFileDesc*)theFolder;
{	
	NTSizeCalculatorTreeNode *result = [self.nodeFolderMap objectForKey:[theFolder dictionaryKey]];
	
	if (!result)
	{
		NSString* treePath = [NTSizeCalculatorTree treePathForPath:theFolder.path];
		
		// what if folder deleted, then a new folder created with same path
		// the tree would still contain the old path and children, we need to fix the tree here before adding path
		NTSizeCalculatorTreeNode *nodeByPath = [self.nodePathMap objectForKey:treePath];
		if (nodeByPath)
		{
			// NSLog(@"-[%@ %@] fixing tree for folder with same path different desc %@", [self className], NSStringFromSelector(_cmd), treePath);
			
			// path exists in tree, need to remove node and it's children
			[self removeNodesAndChildren:[NSArray arrayWithObject:nodeByPath] removeFolders:YES];
		}
		
		result = [self doAddPathToTree:treePath folder:theFolder];
	}
	
	return result;
}

- (NTSizeCalculatorTreeNode*)addPathToTree:(NSString*)thePath;
{
	NTSizeCalculatorTreeNode *result = [self.nodePathMap objectForKey:thePath];
	
	if (!result)
		result = [self doAddPathToTree:thePath folder:nil];
	
	return result;
}

- (NTSizeCalculatorTreeNode*)nodeOrParentForPath:(NSString*)thePath;
{
	NTSizeCalculatorTreeNode *result = [self.nodePathMap objectForKey:thePath];
	
	if (!result)
		result = [self parentForPath:thePath];
	
	return result;	
}

- (NTSizeCalculatorTreeNode*)parentForPath:(NSString*)thePath;
{
	NTSizeCalculatorTreeNode *result = nil;
	
	// search for parent node
	NSString* subPath=thePath;
	while (!result)
	{
		if ([subPath isEqualToString:@"/"] || ![subPath length])  // added [subPath length] to avoid endless loops.  thePath was nil in some cases
			break;
		
		subPath = [subPath stringByDeletingLastPathComponent];
		
		result = [self.nodePathMap objectForKey:subPath];
	}
	
	return result;	
}

- (void)debugTreeNodeForFolder:(NTFileDesc*)theFolder;
{
	NTSizeCalculatorTreeNode *result;
	
	result = [self.nodeFolderMap objectForKey:[theFolder dictionaryKey]];
	if (result)
		NSLog(@"-[%@ %@] node: %@", [self className], NSStringFromSelector(_cmd), [result description]);
	else
		NSLog(@"-[%@ %@] node not in tree: %@", [self className], NSStringFromSelector(_cmd), [theFolder path]);
	
	result = [self.nodePathMap objectForKey:theFolder.path];
	if (result)
		NSLog(@"-[%@ %@] nodepath: %@", [self className], NSStringFromSelector(_cmd), [result description]);
	else
		NSLog(@"-[%@ %@] nodepath not in tree: %@", [self className], NSStringFromSelector(_cmd), [theFolder path]);
	
	result = [self nodeOrParentForPath:theFolder.path];
	if (result)
		NSLog(@"-[%@ %@] nodeInTree: %@", [self className], NSStringFromSelector(_cmd), [result description]);
	else
		NSLog(@"-[%@ %@] nodeInTree not in tree: %@", [self className], NSStringFromSelector(_cmd), [theFolder path]);

	NTFileDesc* folder = [self.folders objectForKey:theFolder.dictionaryKey];
	if (folder)
		NSLog(@"-[%@ %@] folder OK: %@", [self className], NSStringFromSelector(_cmd), [folder description]);
	else
		NSLog(@"-[%@ %@] folder not in folders: %@", [self className], NSStringFromSelector(_cmd), [theFolder path]);
}

@end

// stuff to remove deleted and readd invalid nodes
// called before a calc when verifying a subtree
@implementation NTSizeCalculatorTreeRoot (TreeRepair)

- (void)doRemoveNodesFromTree:(NSArray*)theNodes removedNodes:(NSMutableArray*)removedNodes clearFromParent:(BOOL)clearFromParent;
{
	for (NTSizeCalculatorTreeNode* node in theNodes)
	{
		// add here so parents get added before children.  This will make readding nodes faster
		[removedNodes addObject:node];
		
		// remove children first
		if (node.children)
			[self doRemoveNodesFromTree:[node.children allValues] removedNodes:removedNodes clearFromParent:NO];
		
		if (clearFromParent)
		{
			[node.parent removeChild:node];
			
			// parent now has one less child, so it needs to be marked as needing recalc
			[node.parent setNeedToRecalc:YES];
		}
		
		[self.nodeFolderMap removeObjectForKey:[node.desc dictionaryKey]];
		[self.nodePathMap removeObjectForKey:node.treePath];
	}
}

// returns list of nodes removed
- (NSArray*)removeNodesAndChildren:(NSArray*)theNodes removeFolders:(BOOL)removeFolders;
{
	NSMutableArray* removedNodes = [NSMutableArray array];
	
	[self doRemoveNodesFromTree:theNodes removedNodes:removedNodes clearFromParent:YES];
	
	if (removeFolders)
	{
		for (NTSizeCalculatorTreeNode* node in removedNodes)
			[self.folders removeObjectForKey:[node.desc dictionaryKey]];
	}
	
	return removedNodes;
}

@end

@implementation NTSizeCalculatorTreeRoot (Private)

- (NTSizeCalculatorTreeNode*)doAddPathToTree:(NSString*)thePath folder:(NTFileDesc*)theFolder;
{
	NTSizeCalculatorTreeNode* result=nil;
	NTSizeCalculatorTreeNode *parentNode=[self parentForPath:thePath];
	
	// parentNode found, now build children for the rest of the path
	if (!parentNode)
		NSLog(@"-[%@ %@] parent node not found? %@", [self className], NSStringFromSelector(_cmd), thePath);
	else
	{
		// reshuffle children if necessary
		NSMutableArray* siblings = [NSMutableArray array];
		
		for (NTSizeCalculatorTreeNode* child in [parentNode.children allValues])
		{
			if ([child.treePath hasPrefix:thePath])
			{
				// need to check for "/" at end to be sure it's not a similarly named folder that is matching
				if ([child.treePath characterAtIndex:thePath.length] == '/')
					[siblings addObject:child];
			}
		}
		
		if (!theFolder)
		{
			if ([[[self.rootNode desc] mountPoint] isBootVolume])
				theFolder = [NTFileDesc descNoResolve:thePath];
			else
				theFolder = [NTFileDesc descNoResolve:[[[[self.rootNode desc] mountPoint] path] stringByAppendingString:thePath]];
			
			if (![theFolder isValid])
			{
				// probably an old refresh message getting processed as a folder is deleting contents, should be OK
				theFolder = nil;
			}
		}
		
		if (theFolder && thePath)
		{
			result = [parentNode addChildWithTreePath:thePath folder:theFolder];
			
			if ([siblings count])
			{
				[result addChildren:siblings];
				[parentNode removeChildren:siblings];
			}
			
			// HHH	NSLog(@"ADD: %@", thePath);
			
			// add to our nodePathMap
			[self.nodeFolderMap setObject:result forKey:[theFolder dictionaryKey]];
			[self.nodePathMap setObject:result forKey:thePath];
		}
	}
	
	return result;
}

@end
