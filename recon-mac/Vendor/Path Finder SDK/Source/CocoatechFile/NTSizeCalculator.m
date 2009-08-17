//
//  NTSizeCalculator.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTSizeCalculator.h"
#import "NTSizeCalculatorMgr.h"
#import "NTSyncSizeCalculator.h"
#import "NTFSSize.h"
#import "NTSizeCalculatorTreeMgr.h"

@implementation NTSizeCalculator

@synthesize uniqueID;
@synthesize folder;
@synthesize size;
@synthesize delegate;

+ (NTSizeCalculator*)calculator:(NTFileDesc*)theFolder
					   delegate:(id<NTSizeCalculatorDelegateProtocol>)theDelegate;
{
	if ([theFolder isFile] || [theFolder isComputer])
	{
		NSLog(@"-[%@ %@] ** invalid param", [self className], NSStringFromSelector(_cmd));
		return nil;
	}
	
	NTSizeCalculator* result = [[NTSizeCalculator alloc] init];
	
	result.delegate = theDelegate;
	result.uniqueID = [NSNumber unique];
	result.folder = theFolder;
	result.size = [[NTSizeCalculatorMgr sharedInstance] sizeForKey:theFolder.dictionaryKey];
	
	[[NTSizeCalculatorMgr sharedInstance] addCalculator:result];
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	if (self.delegate)
		[NSException raise:@"must call clear delegate" format:@"%@", NSStringFromClass([self class])];

	self.folder = nil;
	self.uniqueID = nil;
	self.size = nil;
	
    [super dealloc];
}

- (void)clearDelegate;
{
	[[NTSizeCalculatorMgr sharedInstance] removeCalculator:self];

	self.delegate = nil;
}

- (void)setSizeAndNotifyDelegate:(NTFSSize*)theSize;
{
	if (![NSThread isMainThread])
		NSLog(@"-[%@ %@] not main thread", [self className], NSStringFromSelector(_cmd));
	
	if (theSize)
	{
		BOOL updateDelegate=YES;
		
		// is the new size different?
		if (self.size)
		{
			if ([self.size isEqualToSize:theSize])
				updateDelegate = NO;
		}
		
		if (updateDelegate)
		{
			self.size = theSize;
			[[self delegate] sizeCalculatorUpdated:self];
		}
	}
	else
		NSLog(@"-[%@ %@] size nil?", [self className], NSStringFromSelector(_cmd));
}

@end

@implementation NTSizeCalculator (CacheAccess)

+ (NTFSSize*)cachedSize:(NTFileDesc*)theFolder;
{
	// don't look at cache, look at current list of sizeCalculators
	return [[NTSizeCalculatorMgr sharedInstance] sizeForKey:theFolder.dictionaryKey];
}

+ (NTFSSize*)calcSizeSync:(NTFileDesc*)theFolder;
{	
	return [NTSyncSizeCalculator sizeAndValenceForDesc:theFolder subfolders:YES operation:nil cachedSizes:nil];
}

+ (void)debugTreeNodeForFolder:(NTFileDesc*)folder;
{
	[[NTSizeCalculatorTreeMgr sharedInstance] debugTreeNodeForFolder:folder];
}

@end