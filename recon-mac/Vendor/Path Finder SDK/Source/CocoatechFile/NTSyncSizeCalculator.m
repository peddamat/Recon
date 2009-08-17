//
//  NTSyncSizeCalculator.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/31/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTSyncSizeCalculator.h"
#import "NTFSSize.h"
#import "NTVolume.h"
#import "NTFSRefObject.h"

@interface NTSyncSizeCalculator (Private)
- (NTFSSize*)calcSize;
- (NSArray*)ignoreNodeIDs;

// ## outFiles and outFolders are not autoreleased, caller should release them
- (void)directoryContents:(NTFileDesc*)theDesc 
				 outFiles:(NSArray**)outFiles 
			   outFolders:(NSArray**)outFolders;

+ (NTFSSize*)fileSize:(NTFileDesc*)theDesc;
+ (NTFSSize*)volumeSize:(NTFileDesc*)theDesc;
+ (NTFSSize*)computerSize:(NTFileDesc*)theDesc operation:(NSOperation*)theOperation;

- (void)calcFolderSize:(UInt64*)outSize
	   outPhysicalSize:(UInt64*)outPhysicalSize
			outValence:(UInt64*)outValence
			outSubSize:(UInt64*)outSubSize
	outSubPhysicalSize:(UInt64*)outSubPhysicalSize
		 outSubValence:(UInt64*)outSubValence
		   ignoreNodes:(UInt32*)ignoreNodes;

- (void)calcFolderSize:(NSArray*)theDescs
				 files:(BOOL)files
			   outSize:(UInt64*)outSize
	   outPhysicalSize:(UInt64*)outPhysicalSize
			outValence:(UInt64*)outValence
		   ignoreNodes:(UInt32*)ignoreNodes;
@end

@implementation NTSyncSizeCalculator

@synthesize desc;
@synthesize operation;
@synthesize supportsForks;
@synthesize volumeRefNum;
@synthesize subfolders;
@synthesize cachedSizes;

+ (NTFSSize*)sizeAndValenceForDesc:(NTFileDesc*)theDesc
						subfolders:(BOOL)theSubfolders
						 operation:(NSOperation*)theOperation
					   cachedSizes:(NSArray*)theCachedSizes;
{
	NTFSSize* result=nil;
	
	if ([theDesc isFile])
		result = [self fileSize:theDesc];
	else if ([theDesc isComputer])
		result = [self computerSize:theDesc operation:theOperation];
	else if ([theDesc isVolume])
		result = [self volumeSize:theDesc];
	else
	{
		NTSyncSizeCalculator *calculator = [[NTSyncSizeCalculator alloc] init];
		
		calculator.desc = theDesc;
		calculator.operation = theOperation;
		calculator.supportsForks = [[theDesc volume] supportsForks];
		calculator.volumeRefNum = [theDesc volumeRefNum];
		calculator.subfolders = theSubfolders;
		calculator.cachedSizes = theCachedSizes;
		
		result = [calculator calcSize];
		
		[calculator release];
	}
	
	return result;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	self.desc = nil;
	self.operation = nil;
	self.cachedSizes = nil;
	
    [super dealloc];
}

@end

@implementation NTSyncSizeCalculator (Private)

+ (NTFSSize*)fileSize:(NTFileDesc*)theDesc;
{
	UInt64 size = [theDesc size];
	UInt64 physicalSize = [theDesc physicalSize];
	UInt64 valence=1;
	
	return [NTFSSize size:theDesc 
			  contentSize:[NTFSSizeSpec sizeSpec:size physicalSize:physicalSize valence:valence] 
			subfolderSize:nil
				 children:nil];			
}

+ (NTFSSize*)volumeSize:(NTFileDesc*)theDesc
{
	UInt64 size = [NTFileDesc volumeTotalBytes:theDesc] - [NTFileDesc volumeFreeBytes:theDesc];
	UInt64 physicalSize = size;
	UInt64 valence= [[theDesc volume] fileCount] + [[theDesc volume] folderCount];
	
	return [NTFSSize size:theDesc 
			  contentSize:[NTFSSizeSpec sizeSpec:size physicalSize:physicalSize valence:valence] 
			subfolderSize:nil
				 children:nil];		
}

+ (NTFSSize*)computerSize:(NTFileDesc*)theDesc operation:(NSOperation*)theOperation;
{
	UInt64 size = 0;
	UInt64 physicalSize = 0;
	UInt64 valence = 0;
	
	for (NTFileDesc *itemDesc in [theDesc directoryContents:NO resolveIfAlias:NO])
	{
		// don't include network volumes
		if ([itemDesc isVolume] && ![itemDesc isNetwork])
		{
			NTFSSize* folderSize = [self volumeSize:itemDesc];
			
			if (folderSize)
			{
				size += [folderSize size];
				physicalSize += [folderSize physicalSize];
				valence += [folderSize valence];
			}
		}
		
		if ([theOperation isCancelled])
			break;
	}
	
	return [NTFSSize size:theDesc 
			  contentSize:[NTFSSizeSpec sizeSpec:size physicalSize:physicalSize valence:valence] 
			subfolderSize:nil
				 children:nil];	
}

// ## outFiles and outFolders are not autoreleased, caller should release them
- (void)directoryContents:(NTFileDesc*)theDesc 
				 outFiles:(NSArray**)outFiles 
			   outFolders:(NSArray**)outFolders;
{
	NSMutableArray* folders = [[NSMutableArray alloc] initWithCapacity:20];
	NSMutableArray* files = [[NSMutableArray alloc] initWithCapacity:20];
	
	if (self.volumeRefNum == [theDesc volumeRefNum])
	{		
		// must release descs
		NSArray* descs = [theDesc directoryContents:NO resolveIfAlias:NO infoBitmap:kSizeCalculatorCatalogInfoBitmap];
		for (NTFileDesc *itemDesc in descs)
		{
			if ([itemDesc isFile])
				[files addObject:itemDesc];
			else
				[folders addObject:itemDesc];
		}	
		[descs release];
		descs = nil;
	}
	
	*outFiles = files;
	*outFolders = folders;
}

- (NTFSSize*)calcSize
{
    UInt64 physicalSize=0;
	UInt64 valence=0;
	UInt64 size = 0;
    UInt64 subPhysicalSize=0;
	UInt64 subValence=0;
	UInt64 subSize = 0;
		
	// convert ignoreNodes to a C array for quick searching
	NSArray *nodeIDs = [self ignoreNodeIDs];
	UInt32 ignoreNodes[[nodeIDs count]+1];

	int index=0;
	ignoreNodes[index++] = [nodeIDs count];  // first item is count
	for (NSNumber* nodeID in nodeIDs)
		ignoreNodes[index++] = [nodeID unsignedIntValue];
	
	[self calcFolderSize:&size
		 outPhysicalSize:&physicalSize
			  outValence:&valence
			  outSubSize:&subSize
	  outSubPhysicalSize:&subPhysicalSize
		   outSubValence:&subValence
			 ignoreNodes:ignoreNodes];
    
    return [NTFSSize size:[self desc] 
			  contentSize:[NTFSSizeSpec sizeSpec:size physicalSize:physicalSize valence:valence] 
			subfolderSize:(self.subfolders) ? [NTFSSizeSpec sizeSpec:subSize physicalSize:subPhysicalSize valence:subValence] : nil
				 children:self.cachedSizes];
}

- (void)calcFolderSize:(UInt64*)outSize
	   outPhysicalSize:(UInt64*)outPhysicalSize
			outValence:(UInt64*)outValence
			outSubSize:(UInt64*)outSubSize
	outSubPhysicalSize:(UInt64*)outSubPhysicalSize
		 outSubValence:(UInt64*)outSubValence
		   ignoreNodes:(UInt32*)ignoreNodes;
{
	NSArray* files, *folders;
	
	[self directoryContents:self.desc 
				   outFiles:&files 
				 outFolders:&folders];
	
	[self calcFolderSize:files 
				   files:YES
				 outSize:outSize
		 outPhysicalSize:outPhysicalSize
			  outValence:outValence
			 ignoreNodes:ignoreNodes];
	
	[files release];
	files = nil;
	
	if (self.subfolders)
	{
		[self calcFolderSize:folders 
					   files:NO
					 outSize:outSubSize
			 outPhysicalSize:outSubPhysicalSize
				  outValence:outSubValence
				 ignoreNodes:ignoreNodes];
	}
	
	[folders release];
	folders = nil;
}

// recursive function
- (void)calcFolderSize:(NSArray*)theDescs
				 files:(BOOL)files
			   outSize:(UInt64*)outSize
	   outPhysicalSize:(UInt64*)outPhysicalSize
			outValence:(UInt64*)outValence
		   ignoreNodes:(UInt32*)ignoreNodes;
{
	if ([[self operation] isCancelled])
		return;
	
	if (theDescs.count)
	{		
		for (NTFileDesc *itemDesc in theDescs)
		{												
			(*outValence)++;  // add one for this file or folder
			
			if (files)
			{
				if (!self.supportsForks)
				{
					// we don't include the rsrc fork size if there might be a ._ file.
					// If there is a ._file in this directory, it will be counted separately as we interate the folder
					// the size call returns the total size which includes the rsrc data contained in the ._ file
					
					(*outSize) += [itemDesc dataForkSize];
					(*outPhysicalSize) += [itemDesc dataForkPhysicalSize];
				}
				else
				{
					(*outSize) += [itemDesc size];
					(*outPhysicalSize) += [itemDesc physicalSize];
				}
			}
			else
			{
				BOOL ignoreFolder=NO;
				
				// is directory in our ignore list?
				if (ignoreNodes)
				{
					UInt32 itemNode = [itemDesc nodeID];
					UInt32 i, cnt = ignoreNodes[0];
					for (i=0;i<cnt;i++)
					{
						// array is ordered, so we can bail early if numbers get too big
						if (itemNode < ignoreNodes[i+1])
							break;
						else if (itemNode == ignoreNodes[i+1])
							ignoreFolder = YES;
					}
				}
				
				if (ignoreFolder)
					; // NSLog(@"ignoring: %@", [itemDesc path]);
				else
				{
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					
					NSArray* files, *folders;
					
					[self directoryContents:itemDesc 
								   outFiles:&files 
								 outFolders:&folders];
					
					[self calcFolderSize:files 
								   files:YES
								 outSize:outSize
						 outPhysicalSize:outPhysicalSize
							  outValence:outValence
							 ignoreNodes:ignoreNodes];
					
					[files release];
					files = nil;
					
					[self calcFolderSize:folders 
								   files:NO
								 outSize:outSize
						 outPhysicalSize:outPhysicalSize
							  outValence:outValence
							 ignoreNodes:ignoreNodes];
					
					[folders release];
					folders = nil;

					[pool release];
				}
			}
			
			// if thread was stopped, break out of the loop
			if ([[self operation] isCancelled])
				break;
		}
	}
}

- (NSArray*)ignoreNodeIDs;
{
	// first order an array of node ids.  sorting will make searching faster
	NSMutableArray* nodeIDs = [NSMutableArray array];
	for (NTFSSize* ignoreSize in self.cachedSizes)
		[nodeIDs addObject:[NSNumber numberWithUnsignedInt:[[ignoreSize desc] nodeID]]];
	
	[nodeIDs sortUsingSelector:@selector(compare:)];
		
	return nodeIDs;
}	

@end
