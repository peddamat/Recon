//
//  NTListSizeCalculator.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTListSizeCalculator.h"
#import "NTSizeCalculator.h"
#import "NTFSSize.h"
#import "NTSyncSizeCalculator.h"

// ================================================================================

@interface NTListSizeCalculatorThread : NTThreadRunnerParam
{
    NTFSSizeSpec* result;
    NSArray* files;
}

@property (retain) NTFSSizeSpec* result;
@property (retain) NSArray* files;

+ (NTThreadRunner*)thread:(id<NTThreadRunnerDelegateProtocol>)delegate files:(NSArray*)files;

@end

// ================================================================================

@interface NTListSizeCalculator (Protocols) <NTSizeCalculatorDelegateProtocol, NTThreadRunnerDelegateProtocol>
@end

@interface NTListSizeCalculator (Private)
- (void)refreshSize;
- (void)releaseThread;
- (BOOL)calculatorsDone;
@end

@implementation NTListSizeCalculator

@synthesize uniqueID;
@synthesize descs;
@synthesize sizeSpec;
@synthesize delegate;
@synthesize calculators;
@synthesize filesCalcThread;
@synthesize fileSizeSpec;

+ (NTListSizeCalculator*)calculator:(NSArray*)theDescs
					   delegate:(id<NTListSizeCalculatorDelegateProtocol>)theDelegate;
{
	NTListSizeCalculator* result = [[NTListSizeCalculator alloc] init];
	
	result.delegate = theDelegate;
	result.uniqueID = [NSNumber unique];
	result.descs = theDescs;
	result.calculators = [NSMutableArray array];
	
	NSMutableArray* files = [NSMutableArray array];
	for (NTFileDesc* desc in theDescs)
	{
		if (desc.isDirectory && !desc.isComputer)
			[result.calculators addObject:[NTSizeCalculator calculator:desc delegate:result]];
		else
			[files addObject:desc];
	}
		
	if (files.count)
		result.filesCalcThread = [NTListSizeCalculatorThread thread:result files:files];
	
	// set initial size, maybe cached or only files and no folder
	[result performDelayedSelector:@selector(initialUpdate) withObject:nil];

	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	if (self.delegate)
		[NSException raise:@"must call clear delegate" format:@"%@", NSStringFromClass([self class])];
	
	self.descs = nil;
	self.uniqueID = nil;
	self.sizeSpec = nil;
	self.fileSizeSpec = nil;
	
	for (NTSizeCalculator* calculator in self.calculators)
		[calculator clearDelegate];
	self.calculators = nil;
	
	[self releaseThread];
	
    [super dealloc];
}

- (void)clearDelegate;
{	
	self.delegate = nil;
}

@end

@implementation NTListSizeCalculator (Private)

- (void)releaseThread;
{
	[filesCalcThread clearDelegate];
	filesCalcThread = nil;
}

- (void)refreshSize;
{
	if (!self.filesCalcThread && self.calculatorsDone)
	{
		NTFSSizeSpec* result = nil;
		
		for (NTSizeCalculator* calculator in self.calculators)
		{
			NTFSSize* itemSize = calculator.size;
			
			if (!result)
				result = [NTFSSizeSpec sizeSpec:itemSize];
			else
				result = [result sizeByAddingSize:itemSize];
		}
		
		// add file size if any
		if (self.fileSizeSpec)
		{
			if (!result)
				result = self.fileSizeSpec;
			else
				result = [result sizeByAddingSizeSpec:self.fileSizeSpec];
		}
				
		self.sizeSpec = result;
		[[self delegate] listSizeCalculatorUpdated:self];
	}
}

- (void)initialUpdate;
{
	[self refreshSize];
}

- (BOOL)calculatorsDone;
{
	for (NTSizeCalculator* calculator in self.calculators)
	{		
		if (!calculator.size)
			return NO;
	}
	
	return YES;
}

@end

@implementation NTListSizeCalculator (Protocols)

- (void)sizeCalculatorUpdated:(NTSizeCalculator*)sizeCalculator;
{
	[self refreshSize];
}

- (void)threadRunner_complete:(NTThreadRunner*)threadRunner;
{
	self.fileSizeSpec = [(NTListSizeCalculatorThread*) [threadRunner param] result];
	
	[self releaseThread];
	
	[self refreshSize];	
}

@end

// ========================================================================================

@implementation NTListSizeCalculatorThread

@synthesize files;
@synthesize result;

- (void)dealloc
{
	self.result = nil;
	self.files = nil;
	
    [super dealloc];
}

+ (NTThreadRunner*)thread:(id<NTThreadRunnerDelegateProtocol>)delegate files:(NSArray*)files;
{
    NTListSizeCalculatorThread* param = [[[NTListSizeCalculatorThread alloc] init] autorelease];
	
	param.files = files;
	
	return [NTThreadRunner thread:param
						 priority:1
						 delegate:delegate];	
}

@end

@implementation NTListSizeCalculatorThread (Thread)

- (BOOL)doThreadProc;
{	
	NTFSSizeSpec* size = nil;
	
	for (NTFileDesc* theDesc in self.files)
	{
		NTFSSize* itemSize = [NTSyncSizeCalculator sizeAndValenceForDesc:theDesc
															  subfolders:NO
															   operation:nil
															 cachedSizes:nil];
		
		if (!size)
			size = [NTFSSizeSpec sizeSpec:itemSize];
		else
			size = [size sizeByAddingSize:itemSize];
	}
	
	self.result = size;
	
    return (![[self helper] killed]);
}

@end



