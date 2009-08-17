//
//  NTSizeUIModelThread.m
//  SizeModulePlugin
//
//  Created by Steve Gehrman on 2/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTSizeUIModelThread.h"
#import "NTSizeUIModel.h"
#import "NTPluginConstants.h"

@interface NTSizeUIModelThread (hidden)
- (void)setModel:(NTSizeUIModel *)theModel;
- (void)setDescs:(NSArray *)theDescs;
@end

@implementation NTSizeUIModelThread

+ (NTThreadRunner*)thread:(NSArray*)descs
				 delegate:(id<NTThreadRunnerDelegateProtocol>)delegate;
{
    NTSizeUIModelThread* param = [[[NTSizeUIModelThread alloc] init] autorelease];
    
    [param setDescs:descs];
	
	return [NTThreadRunner thread:param
						 priority:.8
						 delegate:delegate];	
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{	
	[self setDescs:nil];
	
    [self setModel:nil];
    [super dealloc];
}

//---------------------------------------------------------- 
//  model 
//---------------------------------------------------------- 
- (NTSizeUIModel *)model
{
	if (!mModel)
		[self setModel:[NTSizeUIModel model]];
	
    return mModel; 
}

- (void)setModel:(NTSizeUIModel *)theModel
{
    if (mModel != theModel)
    {
        [mModel release];
        mModel = [theModel retain];
    }
}

//---------------------------------------------------------- 
//  descs 
//---------------------------------------------------------- 
- (NSArray *)descs
{
    return mDescs; 
}

- (void)setDescs:(NSArray *)theDescs
{
    if (mDescs != theDescs)
    {
        [mDescs release];
        mDescs = [theDescs retain];
    }
}

@end

@implementation NTSizeUIModelThread (Thread)

// override from the base class
- (BOOL)doThreadProc;
{
	NSArray *descs = [self descs];
	if ([descs count])
	{
		NTSizeUIModel* model = [NTSizeUIModel model];		

		NTIcon *icon = nil;
		if ([descs count] > 1)
		{
			[model setName:[NSString stringWithFormat:[NTLocalizedString localize:@"%d items"], [descs count]]];

			icon = [[NTIconStore sharedInstance] smallMultipleFilesIcon];
		}
		else if ([descs count] == 1)
		{
			NTFileDesc* desc = [descs objectAtIndex:0];
			
			[model setName:[desc displayName]];
			
			if ([desc isFile])
			{
				[model setSize:[[NTSizeFormatter sharedInstance] fileSize:[desc physicalSize] allowBytes:NO]];
				[model setSizeToolTip:[[NTSizeFormatter sharedInstance] fileSizeInBytes:[desc physicalSize]]];
			}
			
			[model setInfo:[NSString stringWithFormat:@"%@ %@",[NTLocalizedString localize:@"Modified:" table:@"preview"], [[NTDateFormatter sharedInstance] dateString:[desc modificationDate] format:kLongDate relative:YES]]];

			icon = [(NTFileDesc*)[descs objectAtIndex:0] icon];
		}
		
		// set the icon
		[model setIcon:[icon imageForSize:32 label:0 select:NO]];
		
		// set our result
		[self setModel:model];
	}
	
	return ![[self helper] killed];	
}

@end
