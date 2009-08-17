//
//  NTSizeCalculatorTreeOperation.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTSizeCalculatorTreeOperation.h"
#import "NTSizeCalculatorTreeRoot.h"
#import "NTSizeCalculatorTreeNode.h"
#import "NTSyncSizeCalculator.h"
#import "NTFSEventMessage.h"

@interface NTSizeCalculatorTreeOperation (kNTTreeOperation_calculateTreeNode)
- (void)calculateNextTreeNode;
- (NSArray*)calculateTreeNode:(NTSizeCalculatorTreeNode*)theNode;
- (BOOL)validateTreeNode:(NTSizeCalculatorTreeNode*)theNode treeRoot:(NTSizeCalculatorTreeRoot*)theTreeRoot;
@end

@interface NTSizeCalculatorTreeOperation (kNTTreeOperation_processNewFolders)
- (void)processNewFolders;
@end

@interface NTSizeCalculatorTreeOperation (kNTTreeOperation_processRefreshMessages)
- (void)processRefreshMessages;
@end

@implementation NTSizeCalculatorTreeOperation

@synthesize type;
@synthesize calcingFolderKey;

+ (NTSizeCalculatorTreeOperation*)treeOperation:(NTTreeOperationType)theType
									   delegate:(NSObject<NTOperationDelegateProtocol>*)theDelegate 
										   treeRoot:(NTSizeCalculatorTreeRoot*)theTreeRoot
										   data:(id)theData; // data depends on the type
{
    NTSizeCalculatorTreeOperation* result = (NTSizeCalculatorTreeOperation*)[[self class] operation:theDelegate 
																						  parameter:[NSDictionary dictionaryWithObjectsAndKeys:theTreeRoot, @"treeRoot", theData, @"data", nil]];
	
	result.type = theType;
	
	return result; // already autoreleased
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{	
	self.calcingFolderKey = nil;
    [super dealloc];
}

@end

@implementation NTSizeCalculatorTreeOperation (main)

// must subclass to do work
- (void)main;
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	{
		[NSThread setThreadPriority:1.0];  // is it any faster?
		
		@try {
			
			switch (self.type) {
				case kNTTreeOperation_processNewFolders:
					[self processNewFolders];
					break;
				case kNTTreeOperation_processRefreshMessages:
					[self processRefreshMessages];
					break;
				case kNTTreeOperation_calculateTreeNode:
					[self calculateNextTreeNode];
					break;
				default:
					break;
			}					
		}
		@catch (NSException * e) {
			NSLog(@"-[%@ %@] %@", [self className], NSStringFromSelector(_cmd), [e description]);
		}
		@finally {
		}
		
		[self operationDone];
	}
	[pool release];
}

@end

@implementation NTSizeCalculatorTreeOperation (kNTTreeOperation_processNewFolders)

- (void)processNewFolders;
{
	NSDictionary* param = (NSDictionary*)self.parameter;
	NTSizeCalculatorTreeRoot* tree = [param objectForKey:@"treeRoot"];
	NSArray* folders = (NSArray*)[param objectForKey:@"data"];
	
	for (NTFileDesc* folder in folders)
	{		
		// adds node if it doesn't exist
		NTSizeCalculatorTreeNode* node = [tree addFolderToTree:folder];
		
		if (!node)
			NSLog(@"-[%@ %@] failed to create node?", [self className], NSStringFromSelector(_cmd));
	}
}

@end

@implementation NTSizeCalculatorTreeOperation (kNTTreeOperation_processRefreshMessages)

- (void)processRefreshMessages;
{	
	NSDictionary* param = (NSDictionary*)self.parameter;
	NTSizeCalculatorTreeRoot* tree = [param objectForKey:@"treeRoot"];
	NSArray* messages = (NSArray*)[param objectForKey:@"data"];
	
	// we don't want to grow the tree on a huge spurt of changes like a folder copy
	// if a common change happens again, it will eventually get in the tree 
	BOOL addToTree = messages.count < 20;
		
	for (NTFSEventMessage* message in messages)
	{
		BOOL disableAddToTree = NO;
		
		// path is relative, it looks like myFolder/anotherFolder, could be "" if root path
		NSString* relativePath = message.path;
		
		// filter .folder names (.svn, .fsevents, .Trash)
		// this avoids tracking tons of changes that probably don't effect the size anyway, keeps the tree smaller
		NSString* name = [relativePath lastPathComponent];
		if (name.length && [name characterAtIndex:0] == '.')
			disableAddToTree = YES;
		
		// check for anything in /.TemporaryItems.  XCode uses it to safe save it seems, no reason to flag it
		if ([relativePath hasPrefix:@"/.TemporaryItems/"] || [relativePath isEqualToString:@"/.TemporaryItems"])
			disableAddToTree = YES;
		
		// add a "/" at front of path
		relativePath = [@"/" stringByAppendingString:relativePath];
		
		// only creates a node if it's off of one of the roots children
		NTSizeCalculatorTreeNode* node = nil;
		
		if (addToTree && !disableAddToTree)
			node = [tree addPathToTree:relativePath];
		else
			node = [tree nodeOrParentForPath:relativePath];
		
		if (node)
			[node markDirty:[message rescanSubdirectories]];
	}
}

@end

@implementation NTSizeCalculatorTreeOperation (kNTTreeOperation_calculateTreeNode)

- (NTSizeCalculatorTreeNode*)nextNodeNeedingCalc:(NTSizeCalculatorTreeRoot*)tree;
{
	for (NTFileDesc* folder in [tree.folders allValues])
	{
		NTSizeCalculatorTreeNode* node = [tree.nodeFolderMap objectForKey:[folder dictionaryKey]];
		
		if (node)
		{
			if (!node.sizeIsValid)
				return node;
		}
		else
			NSLog(@"-[%@ %@] folder has no node: %@", [self className], NSStringFromSelector(_cmd), folder.path);
	}
	
	return nil;
}

- (void)calculateNextTreeNode;
{
	NSDictionary* param = (NSDictionary*)self.parameter;
	NTSizeCalculatorTreeRoot* treeRoot = [param objectForKey:@"treeRoot"];
		
	// find a node that's ready to go
	NTSizeCalculatorTreeNode* node=nil;
	do 
	{
		node = [self nextNodeNeedingCalc:treeRoot];
		
		if (node)
		{
			// validate, if tree modified, try again, that node could have been invalid
			BOOL treeWasModified = [self validateTreeNode:node treeRoot:treeRoot];
			if (!treeWasModified)
				break;
		}
		else
			break;
		
	} while (YES);
	
	if (node && !self.isCancelled)
	{
		NSArray* nodesCalced = [self calculateTreeNode:node];
		
		// even if canceled, we might have calced some nodes, so always return what we get back for notifications
		self.result = nodesCalced;
	}
}

- (NSArray*)calculateTreeNode:(NTSizeCalculatorTreeNode*)theNode;
{	
	self.calcingFolderKey = [theNode.desc dictionaryKey];
	NSArray* nodesCalced = [theNode calculateSize:self];	
	self.calcingFolderKey = nil;
	
	return nodesCalced;
}	

// return YES if tree was modified
- (BOOL)validateTreeNode:(NTSizeCalculatorTreeNode*)theNode treeRoot:(NTSizeCalculatorTreeRoot*)theTreeRoot;
{
	// validate children marked needToVerify (call before doing a calc)
	// returns a dictionary of "deleted" and "invalid" nodes
	// the caller will try to add invalid nodes (and their children) back in the tree
	// the caller can notify client of delete nodes (and their children)
	NSDictionary* invalidNodes = [theNode verify];
	NSArray* deleted = [invalidNodes objectForKey:@"deleted"];
	NSArray* invalid = [invalidNodes objectForKey:@"invalid"];
	
	// nodes returned only contain the bad parent, not it's children too, so we need to handle any children
	
	// handle deleted
	if ([deleted count])
	{		
		NSArray* nodesRemoved = [theTreeRoot removeNodesAndChildren:deleted removeFolders:YES];
		
		if (nodesRemoved)
			;
	}
	
	if ([invalid count])
	{
		NSArray* nodesRemoved = [theTreeRoot removeNodesAndChildren:invalid removeFolders:NO]; // don't remove folders, they are still good
	
		// NSLog(@"-[%@ %@] readding nodes to tree (%d)", [self className], NSStringFromSelector(_cmd), nodesRemoved.count);

		// now readd folder to tree
		for (NTSizeCalculatorTreeNode* node in nodesRemoved)
			[theTreeRoot addFolderToTree:node.desc];
	}
	
	return ([deleted count] || [invalid count]);
}	

@end
