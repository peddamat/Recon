//
//  NTSizeCalculatorTreeMgr.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTSizeCalculatorTreeMgr.h"
#import "NTSizeCalculatorTree.h"

/* tree manager
 
 - we keep a tree per volume
 - each tree watches it's volume with FSEvents
 - trees keep nodes for folders requested by the client (NTSizeCalculator)
 - trees keep nodes for detected modifications
 - see NTSizeCalculatorTree.m for more docs
 
 */

@interface NTSizeCalculatorTreeMgr (Private)
- (NSDictionary*)folderDictionary:(NSArray*)theFolders;
@end

@implementation NTSizeCalculatorTreeMgr

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

@synthesize trees;

- (id)init;
{
	self = [super init];
	
	self.trees = [NSMutableDictionary dictionary];
	
	return self;
}

- (void)dealloc;
{
	self.trees = nil;
	
	[super dealloc];
}

- (void)addFolders:(NSArray*)theFolders;
{
	if (![NSThread isMainThread])
		NSLog(@"-[%@ %@] not main thread", [self className], NSStringFromSelector(_cmd));

	NSDictionary* folderDictionary = [self folderDictionary:theFolders];
	NTSizeCalculatorTree* tree;

	// now set the folders for each tree
	for (NSNumber* key in [folderDictionary allKeys])
	{
		tree = [self.trees objectForKey:key];
		[tree addFolders:[folderDictionary objectForKey:key]];
	}
}

- (void)removeFolders:(NSArray*)theFolders;
{
	if (![NSThread isMainThread])
		NSLog(@"-[%@ %@] not main thread", [self className], NSStringFromSelector(_cmd));

	NSDictionary* folderDictionary = [self folderDictionary:theFolders];
	NTSizeCalculatorTree* tree;

	// now set the folders for each tree
	for (NSNumber* key in [folderDictionary allKeys])
	{
		tree = [self.trees objectForKey:key];
		[tree removeFolders:[folderDictionary objectForKey:key]];
	}
}

- (void)debugTreeNodeForFolder:(NTFileDesc*)folder;
{
	NSNumber* key = [NSNumber numberWithInt:[folder volumeRefNum]];
	NTSizeCalculatorTree* tree = [self.trees objectForKey:key];
	
	[tree debugTreeNodeForFolder:folder];
}

@end

@implementation NTSizeCalculatorTreeMgr (Private)

- (NSDictionary*)folderDictionary:(NSArray*)theFolders;
{
	NSMutableDictionary* folderDictionary = [NSMutableDictionary dictionary];
	NSMutableArray* folders;
	NSNumber *key;
	NTSizeCalculatorTree* tree;
	
	for (NTFileDesc *folder in theFolders)
	{
		key = [NSNumber numberWithInt:[folder volumeRefNum]];
		tree = [self.trees objectForKey:key];
		
		if (!tree)
		{
			tree = [NTSizeCalculatorTree treeForVolume:[folder volume]];
			[self.trees setObject:tree forKey:key];
		}
		
		folders = [folderDictionary objectForKey:key];
		if (!folders)
		{
			folders = [NSMutableArray array];
			[folderDictionary setObject:folders forKey:key];
		}
		
		[folders addObject:folder];
	}
	
	return folderDictionary;
}

@end

