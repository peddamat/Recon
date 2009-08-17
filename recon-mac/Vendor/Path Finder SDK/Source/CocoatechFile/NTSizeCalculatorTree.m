//
//  NTSizeCalculatorTree.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTSizeCalculatorTree.h"
#import "NTSizeCalculatorTreeNode.h"
#import "NTSizeCalculatorTreeOperation.h"
#import "NTFolderWatcher.h"
#import "NTFSEventMessage.h"
#import "NTSizeCalculatorMgr.h"
#import "NTSizeCalculatorTreeRoot.h"

/* Documentation: minimal recalc tree
 
 * outside world only creates and releases NTSizeCalculator objects (that's it).  It has a delegate which informs it when the data is calced or refreshed
 * add nodes for new folder requests and folders changed (detected by FSEvents)
 * only recalc changed children when child exists avoiding a total recalc
 * size is calced by calcing children and "everything else"
 * as new changes are added to tree, "everything else" must be recalced which is expensive but hopefully
 * once the common changes are added to tree, the total recalc will be come less and less necessary
 * nodes in the tree keep a relative path to it's folder.  /Volumes/volname is removed if needed.  This makes volume renames easier to deal with
 * volumes sizes are taken by asking the volume it's free/used/valence rather than scanning whole volume
 
 * thread safety
 * tree is always modified and examined one action at a time either in main thread or helper operation thread.  This avoids thread safety issues
 * it also avoids doing too much at once and hogging cpu with new many concurrent recalcs.  Tree is always in a known state per operation so we avoid
 * issues with having the tree change in the middle of a calc or tree rebuild
 
 * NTFSSize structure holds the calced folder size minus any children it knows about.
 * the recalc logic found in NTSyncSizeCalculator ignores folder node IDS you pass in thereby avoiding unnessary calculations on children it knows about
 * some changes are currently ignored.  .folders like .svn and .fsevents and .Trash
 * also ignored is everything inside /.TemporaryItems.  These ignores could cause small inaccuracies in the total, but I wanted to keep the tree small and managable
 * on an svn commit for example, every .svn folder change which could be huge (like PFs svn tree)
 
 * tree validation and removing invalid nodes
 * if node is found to be bad or paths dont match, we readd them to tree so they find their new place in the tree
 
 
 * validation nodes - todo
  - if a node is modified, all children below get marked as needToVerify. the thinking is the one of it's parents may have been
  - renamed or deleted or moved, so we just should check to see if we are OK before attempting a calculation
  - to verify we get the path from the NTFileDesc in the node (which is always freshly calced) and compare it to the tree path
  - if the paths don't match, we know this subtree isn't good, so we re add all the nodes to the tree 
  - if the nodes folder desc say's it no longer exists, we need to tell the tree and notify the client, the client will have to resolve the problem
 
 
 
 # notes, things to add, things to think about
  - don't calc if user is logged out
  - possibly don't constanly recalc caches if constantly updating?  
  - test for disk spinning up to calc?  
  - only calc if app in foreground?
  - only calc if user at machine?  mouse moved? events?
  - should we store relative paths in the nodes?  Does that help anything?
  - big folder copy leads to lots of refresh messages and a large tree
  - moving folder to trash moves it's location to .Trash.  desc is still "valid" but path is not what we need.  tree could get wacky
  - when rebuilding, only add back nodes that user requested?
  - filter out .Trashes per volume, ignore refreshes, don't count as total on anything at least not home dir
  - if flood of change messages come in, don't add to tree, this is probably .svn shit or folder copy
 
 Cases:
 1) Folders contents changed
	 - recalc children if needed
	 - calc everything else and add children to result
	 - we could try to minimize future recalcs by adding folders top level subfolders to tree if valence is huge
     - we could by default always add subfolders for Home directory and a few other locations to avoid recalcs
 
 2) a child changes (FSEvent)
	 - parents of children are notified that a child has changed all the way up the tree which triggers rebuilds
	 a) A known child changes
		 - nodes "everything else" size is still good, so total recalc is avoided
		 - node combines previous NTFSSize with a new set of children (same children used in previous NTFSSize)
		 - new children that were added must not be added to the parents size since it's everything else already includes this size
		 - next time parent is modifed, it will do a recalc and add any new children at this point
	 
	 b) A new child is added by the change
		 - must total recalc and add new child, expensive case, but should become less frequent as tree grows
 
 3) A new child is added for a request
	 - node is still good, don't recalc it
	 - this new child can't be used until the next recalc of node
	 - not added if nodes size if another child changes, must intelligently merge NTFSSize to add existing children and not this new one
	 
 */

@interface NTSizeCalculatorTree (Protocols) <NTOperationDelegateProtocol, NTFolderWatcherDelegateProtocol>
@end

@interface NTSizeCalculatorTree (Private)
- (void)performNextOperation;
- (void)startOperation:(NTSizeCalculatorTreeOperation*)operation;
- (void)clearOperation;
@end

@interface NTSizeCalculatorTree (DelayTimers) 
- (void)scheduleOperationType:(NTTreeOperationType)type;

- (void)schedulePendingFoldersOperationAterDelay;
- (void)schedulePendingFoldersOperation;
- (void)schedulePendingRefreshOperationAterDelay;
- (void)schedulePendingRefreshOperation;
@end

@implementation NTSizeCalculatorTree

@synthesize pendingFolders;
@synthesize pendingRemoveFolders;
@synthesize pendingRefreshMessages;
@synthesize queue;
@synthesize operation;
@synthesize watcher;
@synthesize pendingOperations;
@synthesize sentDelayedPerformPendingRefresh;
@synthesize sentDelayedPerformPendingFolders;
@synthesize treeRoot;

+ (NTSizeCalculatorTree*)treeForVolume:(NTVolume*)theVolume;
{
	NTSizeCalculatorTree* result = [[NTSizeCalculatorTree alloc] init];
	
	result.treeRoot = [NTSizeCalculatorTreeRoot treeRootForVolume:theVolume];
	result.pendingFolders = [NSMutableDictionary dictionary];
	result.pendingRemoveFolders = [NSMutableDictionary dictionary];
	result.pendingRefreshMessages = [NSMutableDictionary dictionary];
	result.pendingOperations = [NSMutableArray array];
	result.queue = [[[NSOperationQueue alloc] init] autorelease];

	// start watcher
	result.watcher = [NTFolderWatcher watcher:result folder:[theVolume mountPoint] watchSubfolders:YES latency:5.0];
	
	return [result autorelease];
}

- (void)dealloc;
{
	self.treeRoot = nil;
	self.pendingFolders = nil;
	self.pendingRemoveFolders = nil;
	self.pendingRefreshMessages = nil;
	self.queue = nil;
	
	[self.watcher clearDelegate];
	self.watcher = nil;
	
	self.pendingOperations = nil;

	[self clearOperation];
		
	[super dealloc];
}

+ (NSString*)treePathForPath:(NSString*)thePath;
{
	NSString* result = thePath;
	
	// remove volumes to make it relative
	if ([result hasPrefix:@"/Volumes/"])
	{
		result = [result stringByDeletingPrefix:@"/Volumes/"];
		
		// delete up to the next "/" to remove volume name
		NSRange range = [result rangeOfString:@"/"];
		if (range.location != NSNotFound)
			result = [result substringFromIndex:range.location];
		else
			result = @"/";  // must have been a volume path /Volumes/Development
	}
	
	return result;
}

- (void)addFolders:(NSArray*)theFolders;
{
	if (![NSThread isMainThread])
		NSLog(@"-[%@ %@] not main thread", [self className], NSStringFromSelector(_cmd));

	for (NTFileDesc* folder in theFolders)
		[self.pendingFolders setObject:folder forKey:[folder dictionaryKey]];
	
	[self schedulePendingFoldersOperation];
}

- (void)removeFolders:(NSArray*)theFolders;
{
	if (![NSThread isMainThread])
		NSLog(@"-[%@ %@] not main thread", [self className], NSStringFromSelector(_cmd));

	for (NTFileDesc* folder in theFolders)
	{
		NSString* key = [folder dictionaryKey];
		
		// cancel any calc operations if running on this directory
		if ([self.operation type] == kNTTreeOperation_calculateTreeNode)
		{
			if ([[self.operation calcingFolderKey] isEqualToString:key])
				[self.operation cancel];
		}
		
		if ([self.pendingFolders objectForKey:key])
			[self.pendingFolders removeObjectForKey:key];
		else
		{
			[self.pendingRemoveFolders setObject:folder forKey:[folder dictionaryKey]];
			
			[self schedulePendingFoldersOperation];
		}
	}
}

- (void)debugTreeNodeForFolder:(NTFileDesc*)theFolder;
{
	[self.treeRoot debugTreeNodeForFolder:theFolder];
}

@end

@implementation NTSizeCalculatorTree (Private)

- (void)performNextOperation;
{
	// operation running, just return
	if (self.operation)
		return;
		
	if (self.pendingOperations.count)
	{
		NSNumber *next = [self.pendingOperations objectAtIndex:0];
		[self.pendingOperations removeObjectAtIndex:0];
		
		// ** always process removed folders regardless to avoid unnecessary calculations
		if ([self.pendingRemoveFolders count])
		{
			// no operations running now, so safe to modify
			[[self.treeRoot folders] removeObjectsForKeys:[self.pendingRemoveFolders allKeys]];
			
			// replace should be thread safe
			self.pendingRemoveFolders = [NSMutableDictionary dictionary];
		}
				
		switch ([next intValue])
		{
			case kNTTreeOperation_processNewFolders:
			{
				if ([self.pendingFolders count])
				{
					// no operations running now, so safe to modify
					[[self.treeRoot folders] addEntriesFromDictionary:self.pendingFolders];

					[self startOperation:[NTSizeCalculatorTreeOperation treeOperation:kNTTreeOperation_processNewFolders delegate:self treeRoot:self.treeRoot data:[self.pendingFolders allValues]]];
					
					// replace should be thread safe
					self.pendingFolders = [NSMutableDictionary dictionary];
				}
			}
				break;
			case kNTTreeOperation_processRefreshMessages:
			{
				if ([self.pendingRefreshMessages count])
				{
					[self startOperation:[NTSizeCalculatorTreeOperation treeOperation:kNTTreeOperation_processRefreshMessages delegate:self treeRoot:self.treeRoot data:[self.pendingRefreshMessages allValues]]];
					
					// replace should be thread safe
					self.pendingRefreshMessages = [NSMutableDictionary dictionary];
				}				
			}
				break;
			case kNTTreeOperation_calculateTreeNode:
			{
				// do a calculate
				[self startOperation:[NTSizeCalculatorTreeOperation treeOperation:kNTTreeOperation_calculateTreeNode delegate:self treeRoot:self.treeRoot data:nil]];
			}
				break;
			default:
				break;
		}
	}	
}

- (NSString*)description;
{
	return [NSString stringWithFormat:@"nodes in table: %d", [[self.treeRoot nodePathMap] count]];
	//	return [self.rootNode description];
}

- (void)startOperation:(NTSizeCalculatorTreeOperation*)theOperation;
{
	if (theOperation)
	{
		if (!self.operation)
		{
			self.operation = theOperation;
			[self.queue addOperation:self.operation];
		}
		else
			NSLog(@"-[%@ %@] operation already running", [self className], NSStringFromSelector(_cmd));
	}
}

- (void)clearOperation;
{
	[self.operation clearDelegate];
	self.operation = nil;
}

@end

@implementation NTSizeCalculatorTree (DelayTimers) 

- (void)schedulePendingFoldersOperationAterDelay;
{
	self.sentDelayedPerformPendingFolders = NO;
	[self scheduleOperationType:kNTTreeOperation_processNewFolders];

	[self performNextOperation];
}

- (void)schedulePendingFoldersOperation;
{
	if (!self.sentDelayedPerformPendingFolders)
	{
		self.sentDelayedPerformPendingFolders = YES;
		
		[self performDelayedSelector:@selector(schedulePendingFoldersOperationAterDelay) withObject:nil delay:0.1];
	}
}

- (void)schedulePendingRefreshOperationAterDelay;
{
	self.sentDelayedPerformPendingRefresh = NO;
	[self scheduleOperationType:kNTTreeOperation_processRefreshMessages];
	
	[self performNextOperation];
}

- (void)schedulePendingRefreshOperation;
{
	if (!self.sentDelayedPerformPendingRefresh)
	{
		self.sentDelayedPerformPendingRefresh = YES;
		
		[self performDelayedSelector:@selector(schedulePendingRefreshOperationAterDelay) withObject:nil delay:0.1];
	}
}

- (void)scheduleOperationType:(NTTreeOperationType)type;
{
	NSNumber* num = [NSNumber numberWithInt:type];
	
	if (![self.pendingOperations containsObject:num])
		[self.pendingOperations addObject:num];
}

@end

@implementation NTSizeCalculatorTree (Protocols) 

// <NTOperationDelegateProtocol>

- (void)operation_complete:(NTOperation*)theOperation;
{
	if (![NSThread isMainThread])
		NSLog(@"-[%@ %@] not main thread", [self className], NSStringFromSelector(_cmd));

	if (theOperation == self.operation)
	{
		switch (self.operation.type)
		{
			case kNTTreeOperation_processNewFolders:
				[self scheduleOperationType:kNTTreeOperation_calculateTreeNode];
				break;
			case kNTTreeOperation_processRefreshMessages:
				[self scheduleOperationType:kNTTreeOperation_calculateTreeNode];
				break;
			case kNTTreeOperation_calculateTreeNode:
			{				
				NSArray* nodesTouched = operation.result;
				
				// even if we get canceled, we still need to notify the results we have
				// nil node means nothing was calced
				if (nodesTouched.count)
				{
					for (NTSizeCalculatorTreeNode* node in nodesTouched)
						[[NTSizeCalculatorMgr sharedInstance] folderSizeUpdated:node.desc size:node.size];
					
					[self scheduleOperationType:kNTTreeOperation_calculateTreeNode];
				}				
				else 
				{
					// node count is nil, but maybe it was because of a cancel?
					// need to schedule the next calc so our loop can continue
					if (operation.isCancelled)
						[self scheduleOperationType:kNTTreeOperation_calculateTreeNode];
				}
			}
				break;
			default:
				break;
		}
				
		[self clearOperation];
	}
	
	// start next task
	[self performNextOperation];
}

// <NTFolderWatcherDelegateProtocol>

- (void)folderWatcher:(NTFolderWatcher*)theWatcher
			   folder:(NTFileDesc*)theFolder
			 messages:(NSArray*)theMessages;  // NTFSEventMessage*
{
	if (![NSThread isMainThread])
		NSLog(@"-[%@ %@] not main thread", [self className], NSStringFromSelector(_cmd));

	for (NTFSEventMessage* inMessage in theMessages)
	{
		NTFSEventMessage* message = [self.pendingRefreshMessages objectForKey:inMessage.path];
		
		// item already exists, add the paths and the rescan flag
		if (message)
			[message updateMessage:inMessage.rescanSubdirectories];
		else
			[self.pendingRefreshMessages setObject:inMessage forKey:inMessage.path];
	}
	
	// start next task
	[self schedulePendingRefreshOperation];
}

@end

