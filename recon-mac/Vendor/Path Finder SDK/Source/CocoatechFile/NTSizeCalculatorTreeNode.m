//
//  NTSizeCalculatorTreeNode.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTSizeCalculatorTreeNode.h"
#import "NTSyncSizeCalculator.h"
#import "NTFSSize.h"
#import "NTSizeCalculatorTree.h"

@interface NTSizeCalculatorTreeNode (Private)
+ (NTSizeCalculatorTreeNode*)node:(NTSizeCalculatorTreeNode*)theParent treePath:(NSString*)theTreePath folder:(NTFileDesc*)theFolder;

- (void)markAllChildrenNeedVerify:(BOOL)isChild;
- (void)markAllChildrenNeedsRecalc:(BOOL)isChild;
@end

@interface NTSizeCalculatorTreeNode (SizeCalculation)
- (void)doCalculateSize:(NSOperation*)operation nodesTouched:(NSMutableArray*)nodesTouched;

- (NTFSSize*)doCalculateContents:(NSOperation*)operation;
- (void)doCalculateChildren:(NSOperation*)operation nodesTouched:(NSMutableArray*)nodesTouched;
- (NTFSSize*)doCalculateVolume:(NSOperation*)operation;
- (NTFSSize*)doCombineSizeWithUpdatedChildren:(NSOperation*)operation;
- (BOOL)childrenMatchCalcedSizesChildren;
- (NSArray*)childSizesUsingPreviousSize:(NTFSSize*)previousSize;
@end

@interface NTSizeCalculatorTreeNode (Validation)
- (void)doVerify:(NSMutableArray*)invalidNodes deletedNodes:(NSMutableArray*)deletedNodes;
@end

@implementation NTSizeCalculatorTreeNode

@synthesize parent;
@synthesize children;
@synthesize treePath;
@synthesize size;
@synthesize desc;
@synthesize needToRecalc;
@synthesize needToRecalcChildren;
@synthesize needToVerify;

// dynamic
@dynamic sizeIsValid;

+ (NTSizeCalculatorTreeNode*)rootNode:(NTFileDesc*)theFolder;
{
	NTSizeCalculatorTreeNode* result = [NTSizeCalculatorTreeNode node:nil treePath:@"/" folder:theFolder];
	
	return result;
}

- (void)dealloc;
{
	self.parent = nil; // not retained, but here for good form
	self.children = nil;
	self.treePath = nil;
	self.desc = nil;
	self.size = nil;
	
	[super dealloc];
}

- (NTSizeCalculatorTreeNode*)addChildWithTreePath:(NSString*)theTreePath folder:(NTFileDesc*)theFolder;
{
	NTSizeCalculatorTreeNode* result = nil;
	
	result = [self.children objectForKey:theTreePath];
	if (!result)
	{
		result = [NTSizeCalculatorTreeNode node:self treePath:theTreePath folder:theFolder];
		
		[self addChild:result];
	}
	
	result = [[result retain] autorelease];
	
	return result;
}

- (void)markDirty:(BOOL)mustRescanChildren;
{
	if (!self.needToRecalc)
	{
		// HHH NSLog(@"DIRTY: %@", [self description]);
		
		// mark self as needing recalc
		self.needToRecalc = YES;
		
		// alert parents above this node need to know we need recalc
		NTSizeCalculatorTreeNode* startNode = self;
		while (startNode = startNode.parent)
			startNode.needToRecalcChildren = YES;	

		// alert children that we were marked dirty and they need to verify that they are still in the tree
		[self markAllChildrenNeedVerify:NO];
	}
	
	// if rescan, mark all children need recalc
	if (mustRescanChildren)
		[self markAllChildrenNeedsRecalc:NO];
}

// used when shuffling children around on a tree reshuffle
- (void)addChildren:(NSArray*)theChildren;
{
	for (NTSizeCalculatorTreeNode* child in theChildren)
	{
		// update childs parent to self
		child.parent = self;
		[self addChild:child];
	}
}

- (void)removeChildren:(NSArray*)theChildren;
{
	for (NTSizeCalculatorTreeNode* child in theChildren)
		[self removeChild:child];
}

// call this instead of directly adding to children dictionary, this creates the mutable dict lazily
- (void)addChild:(NTSizeCalculatorTreeNode*)theChild;
{
	// create lazily
	if (!self.children)
		self.children = [NSMutableDictionary dictionary];
	
	[self.children setObject:theChild forKey:theChild.treePath];
}

- (void)removeChild:(NTSizeCalculatorTreeNode*)theChild;
{
	[self.children removeObjectForKey:theChild.treePath];
}

// returns nodes that were recalced (so that we can send out all notifications even if children were calced)
- (NSArray*)calculateSize:(NSOperation*)operation;
{
	NSMutableArray* nodesTouched = [NSMutableArray array];
	
	[self doCalculateSize:operation nodesTouched:nodesTouched];
	
	return nodesTouched;
}

- (BOOL)sizeIsValid;
{
	return (!self.needToRecalc && !self.needToRecalcChildren);
}

// validate children marked needToVerify
// returns a dictionary of "deleted" and "invalid" nodes
// the caller will try to add invalid nodes (and their children) back in the tree
// the caller can notify client of delete nodes (and their children)
- (NSDictionary*)verify;
{
	NSMutableArray* invalidNodes = [NSMutableArray array];
	NSMutableArray* deletedNodes = [NSMutableArray array];
	
	[self doVerify:invalidNodes deletedNodes:deletedNodes];
	
	return [NSDictionary dictionaryWithObjectsAndKeys:deletedNodes, @"deleted", invalidNodes, @"invalid", nil];
}

@end

@implementation NTSizeCalculatorTreeNode (Private)

+ (NTSizeCalculatorTreeNode*)node:(NTSizeCalculatorTreeNode*)theParent treePath:(NSString*)theTreePath folder:(NTFileDesc*)theFolder;
{
	NTSizeCalculatorTreeNode* result = [[NTSizeCalculatorTreeNode alloc] init];
	
	result.parent = theParent;
	result.treePath = theTreePath;
	result.desc = theFolder;
	
	// default to YES
	result.needToRecalcChildren = YES;
	result.needToRecalc = YES;
	
	// need to verify should be NO, just added here for completeness
	// result.needToVerify = NO;
	
	return [result autorelease];
}

- (NSString*)description;
{
	NSMutableString* result = [NSMutableString string];
	
	if (YES)
		[result appendFormat:@"node(children:%d size:%@ sizeValid:%@) \"%@\"", [[self.children allValues] count], [self.size description], (self.sizeIsValid) ? @"YES":@"NO", [self.desc path]];
	else
	{	
		[result appendString:self.treePath];
		[result appendFormat:@" (children %d)", [[self.children allValues] count]];
		
		for (NTSizeCalculatorTreeNode *node in [self.children allValues])
			[result appendFormat:@"\nchild:  %@", [node description]];
	}
	
	return result;
}

- (void)markAllChildrenNeedVerify:(BOOL)isChild;
{
	if (isChild)
		self.needToVerify = YES;
	
	for (NTSizeCalculatorTreeNode* child in [self.children allValues])
		[child markAllChildrenNeedVerify:YES];
}

- (void)markAllChildrenNeedsRecalc:(BOOL)isChild;
{
	self.needToRecalcChildren = YES;
	
	if (isChild)
		self.needToRecalc = YES;
	
	for (NTSizeCalculatorTreeNode* child in [self.children allValues])
		[child markAllChildrenNeedsRecalc:YES];
}

@end

@implementation NTSizeCalculatorTreeNode (SizeCalculation)

- (void)doCalculateSize:(NSOperation*)operation nodesTouched:(NSMutableArray*)nodesTouched;
{		
	if (!self.sizeIsValid)
	{
		NTFSSize* result=nil;
				
		// don't calc volumes, just use the OS to get it's size
		if ([self.desc isVolume])
			result = [self doCalculateVolume:operation];
		else
		{			
			// special case, we are not marked to calc children. new children may have been added with refreshes
			// if we are going to recalc, might as well pick up those new children, so check for that and trigger a child rebuild
			// if we have new children
			if (self.needToRecalc && !self.needToRecalcChildren)
			{
				if (![self childrenMatchCalcedSizesChildren])
					self.needToRecalcChildren = YES;
			}
			
			// do the children need a recalc?
			if (self.needToRecalcChildren)
				[self doCalculateChildren:operation nodesTouched:nodesTouched];
			
			// does the content need a recalc?
			if (self.needToRecalc)
				result = [self doCalculateContents:operation];
			else
				result = [self doCombineSizeWithUpdatedChildren:operation];
		}
				
		// set the result
		if (!operation.isCancelled)
		{
			if (result)
			{
				// setting nodes state to calculated, adding size and adding to nodesTouched array - this nodes good to go
				self.needToRecalc = NO;
				self.needToRecalcChildren = NO;
				self.size = result;		
				
				// add to front of array, this will put the parent in front of children so adding later will be more effient 
				[nodesTouched insertObject:self atIndex:0];
			}
			else
				NSLog(@"-[%@ %@] result nil? (!operation.isCancelled && !result)", [self className], NSStringFromSelector(_cmd));
		}
	}
}

- (NTFSSize*)doCalculateContents:(NSOperation*)operation;
{
	NTFSSize* result=nil;

	if (!operation.isCancelled)
	{
		result = [NTSyncSizeCalculator sizeAndValenceForDesc:self.desc subfolders:YES operation:operation cachedSizes:[self childSizesUsingPreviousSize:nil]];
		if (operation.isCancelled)
			result = nil;
	}
	
	return result;
}

- (void)doCalculateChildren:(NSOperation*)operation nodesTouched:(NSMutableArray*)nodesTouched
{
	if (!operation.isCancelled)
	{
		// calc all children recursively
		for (NTSizeCalculatorTreeNode* node in [self.children allValues])
		{		
			[node doCalculateSize:operation nodesTouched:nodesTouched];
			
			if (operation.isCancelled)
				break;
		}
		
		if (!operation.isCancelled)
		{
			// children were recalced, so need to check for a special case
			if (!self.needToRecalc)
			{
				// need to recalc total if a child is modified that isn't part of our previous size tree
				// we don't always mark a recalc if a child is added, that's fine, but if a child modifies itself
				// this node needs to update taking into account that new childs total
				
				if (![self childrenMatchCalcedSizesChildren])
					self.needToRecalc = YES;
			}							
		}
	}	
}
	
- (NTFSSize*)doCalculateVolume:(NSOperation*)operation;
{
	NTFSSize* result = nil;
	
	if (!operation.isCancelled)
	{
		result = [NTSyncSizeCalculator sizeAndValenceForDesc:self.desc subfolders:YES operation:operation cachedSizes:nil];
		
		if (operation.isCancelled)
			result = nil;
	}
	
	return result;
}

- (NTFSSize*)doCombineSizeWithUpdatedChildren:(NSOperation*)operation;
{
	NTFSSize* result = nil;

	if (!operation.isCancelled)
	{
		// contents are still good, so rebuild NTFSSize with recalced children that were in our previoius NTFSSize
		if (self.size)
		{
			NSArray* newChildSizes = [self childSizesUsingPreviousSize:self.size];
			
			result = [self.size sizeByReplacingChildren:newChildSizes];
		}
		else
			NSLog(@"-[%@ %@] size nil?", [self className], NSStringFromSelector(_cmd));
	}
	
	return result;
}

- (BOOL)childrenMatchCalcedSizesChildren;
{
	NSArray* theChildren = [self.children allValues];
	NSSet* childNodeIDs = [self.size childNodeIDs];
	
	if (theChildren.count != childNodeIDs.count)
		return NO;
	else
	{
		for (NTSizeCalculatorTreeNode* child in theChildren)
		{
			if (![childNodeIDs member:[NSNumber numberWithUnsignedInt:[child.desc nodeID]]])
				return NO;
		}
	}
	
	return YES;
}

- (NSArray*)childSizesUsingPreviousSize:(NTFSSize*)previousSize;
{
	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[self.children count]];
	NSSet* childNodeIDs = nil;
	
	if (previousSize)
	{
		childNodeIDs = [self.size childNodeIDs];
		if (!childNodeIDs.count)
			NSLog(@"-[%@ %@] no children? %@", [self className], NSStringFromSelector(_cmd), treePath);
	}
	
	// this code executes when one of the children was changed, but the content was OK
	// we need to avoid adding children that are new request nodes which size is already included in our totals (see notes in NTSizeCalculatorTree.m)
	for (NTSizeCalculatorTreeNode* node in [self.children allValues])
	{
		if (!node.size)
			NSLog(@"-[%@ %@] node size is nil? %@", [self className], NSStringFromSelector(_cmd), node.treePath);
		else
		{
			if (childNodeIDs)
			{
				NSNumber *nodeID = [NSNumber numberWithUnsignedInt:[node.desc nodeID]];
				
				// not in our set? skip it
				if (![childNodeIDs member:nodeID])
					continue;
			}
			
			[result addObject:node.size];
		}
	}
		
	return result;
}

@end

@implementation NTSizeCalculatorTreeNode (Validation)

- (void)doVerify:(NSMutableArray*)invalidNodes deletedNodes:(NSMutableArray*)deletedNodes;
{
	BOOL nodeBad = NO; // we always check children unless we find a problem
	
	if (self.needToVerify)
	{
		// get fresh path, compare to the nodes stored path
		NSString* relativePath = [NTSizeCalculatorTree treePathForPath:[self.desc path]];
		
		if ([relativePath isEqualToString:self.treePath])			
			self.needToVerify = NO;  // set back to NO, this child is good
		else
		{
			nodeBad = YES;  // problem, don't check children
			
			// paths don't match.  Does the file still exist?
			if ([self.desc stillExists])
			{
				[invalidNodes addObject:self];
				// NSLog(@"-[%@ %@] node bad, readd to tree: %@", [self className], NSStringFromSelector(_cmd), self.treePath);
			}
			else
			{
				[deletedNodes addObject:self];
				// NSLog(@"-[%@ %@] node bad, deleted: %@", [self className], NSStringFromSelector(_cmd), self.treePath);
			}
		}
	}
	
	// if child was good, check it's children
	if (!nodeBad) 
	{
		for (NTSizeCalculatorTreeNode* aChild in [self.children allValues])
			[aChild doVerify:invalidNodes deletedNodes:deletedNodes];
	}
}

@end

