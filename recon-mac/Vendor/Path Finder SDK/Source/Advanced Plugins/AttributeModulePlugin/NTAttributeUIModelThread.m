//
//  NTAttributeUIModelThread.m
//  AttributeModulePlugin
//
//  Created by Steve Gehrman on 1/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTAttributeUIModelThread.h"
#import "NTAttributeUIModel.h"
#import "NTPluginConstants.h"

@interface NTAttributeUIModelThread (Private)
- (NSArray *)descs;
- (void)setDescs:(NSArray *)theDescs;

- (NSCellStateValue)buttonState:(NSCellStateValue)state 
				   forAttribute:(NTFileAttributeID)attributeID
						   desc:(NTFileDesc*)desc;
@end

@interface NTAttributeUIModelThread (hidden)
- (void)setModel:(NTAttributeUIModel *)theModel;
@end

static const int kUndefinedState = 2;

@implementation NTAttributeUIModelThread

+ (NTThreadRunner*)thread:(NSArray*)descs
				 delegate:(id<NTThreadRunnerDelegateProtocol>)delegate;
{
    NTAttributeUIModelThread* param = [[[NTAttributeUIModelThread alloc] init] autorelease];
    
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
- (NTAttributeUIModel *)model
{
    return mModel; 
}

- (void)setModel:(NTAttributeUIModel *)theModel
{
    if (mModel != theModel)
    {
        [mModel release];
        mModel = [theModel retain];
    }
}

@end

@implementation NTAttributeUIModelThread (Private)

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

- (NSCellStateValue)buttonState:(NSCellStateValue)state 
				   forAttribute:(NTFileAttributeID)attributeID
						   desc:(NTFileDesc*)desc;
{
	if (state != NSMixedState)
	{
		int bbool = NO;
		
		switch (attributeID)
		{
			case kLocked_attributeID:
				bbool = [desc isLocked];
				break;
			case kInvisible_attributeID:
				bbool = [desc isInvisible];
				break;
			case kExtensionHidden_attributeID:
				bbool = [desc isExtensionHidden];
				break;
			case kStationeryPad_attributeID:
				bbool = [desc isStationery];
				break;
			case kHasBundle_attributeID:
				bbool = [desc isBundleBitSet];
				break;
			case kAlias_attributeID:
				bbool = [desc isAliasBitSet];
				break;
			case kCustomIcon_attributeID:
				bbool = [desc hasCustomIcon];
				break;
				
			case kOnDesktop_attributeID:
			case kInited_attributeID:
			case kNameLocked_attributeID:
			case kLabel_attributeID:
			case kLength_attributeID:
			case kType_attributeID:
			case kCreator_attributeID:
			case kAttributeModificationDate_attributeID:
			case kModificationDate_attributeID:
			case kCreationDate_attributeID:
			case kOwner_attributeID:
			case kGroup_attributeID:
			case kPermissions_attributeID:
			case kStickyBit_attributeID:
			case kSpotlightComments_attributeID:
			default:
				NSLog(@"-[%@ %@] shouldn't get here!", [self className], NSStringFromSelector(_cmd));
				break;
		}
		
		NSCellStateValue newState = (bbool ? NSOnState : NSOffState);
		
		if (state == kUndefinedState)
			state = newState;
		else if (state != newState)
			state = NSMixedState;
	}
	
	return state;
}

@end

@implementation NTAttributeUIModelThread (Thread)

// override from the base class
- (BOOL)doThreadProc;
{
	NSArray *descs = [self descs];
	if ([descs count])
	{
		NTFileDesc* desc;
		int labelBits = 0;
		NSString* comments = nil;
		BOOL commentsMatch=YES;
		NSString* type = nil;
		BOOL typesMatch=YES;
		NSString* creator = nil;
		BOOL creatorsMatch=YES;
		
		NTAttributeUIModel* model = [NTAttributeUIModel model];

		// check box values
		NSCellStateValue locked = kUndefinedState;	
		NSCellStateValue invisible = kUndefinedState;	
		NSCellStateValue hideExtension = kUndefinedState;	
		NSCellStateValue stationeryPad = kUndefinedState;	
		NSCellStateValue bundleBit = kUndefinedState;	
		NSCellStateValue aliasBit = kUndefinedState;
		NSCellStateValue customIcon = kUndefinedState;
		
		[model setWritable:YES];  // set to NO if we find an desc not writable
		
		// loop on descs
		for (desc in descs)
		{
			[model setFile:[desc isFile]];
			
			// is writeable
			if (![desc isWritable])
				[model setWritable:NO];
			
			// label
			labelBits |= (1 << [desc label]);
			
			locked = [self buttonState:locked forAttribute:kLocked_attributeID desc:desc];
			invisible  = [self buttonState:invisible forAttribute:kInvisible_attributeID desc:desc];	
			hideExtension  = [self buttonState:hideExtension forAttribute:kExtensionHidden_attributeID desc:desc];	
			stationeryPad  = [self buttonState:stationeryPad forAttribute:kStationeryPad_attributeID desc:desc];	
			bundleBit  = [self buttonState:bundleBit forAttribute:kHasBundle_attributeID desc:desc];	
			aliasBit  = [self buttonState:aliasBit forAttribute:kAlias_attributeID desc:desc];
			customIcon  = [self buttonState:customIcon forAttribute:kCustomIcon_attributeID desc:desc];
			
			NSString* newString;
			
			// handle comments
			if (commentsMatch)
			{
				newString = [desc comments];
				if (!comments)
					comments = newString;
				else if (![comments isEqualToString:newString])
					commentsMatch = NO;
			}
			
			// handle type
			if (typesMatch)
			{
				newString = [NTUtilities intToString:[desc type]];
				if (!type)
					type = newString;
				else if (![type isEqualToString:newString])
					typesMatch = NO;
			}
			
			// handle creator
			if (creatorsMatch)
			{
				newString = [NTUtilities intToString:[desc creator]];
				if (!creator)
					creator = newString;
				else if (![creator isEqualToString:newString])
					creatorsMatch = NO;
			}
		}
		
		// set attributes to model
		[model setLocked:locked];
		[model setInvisible:invisible];
		[model setHideExtension:hideExtension];
		[model setStationeryPad:stationeryPad];
		[model setBundleBit:bundleBit];
		[model setAliasBit:aliasBit];
		[model setCustomIcon:customIcon];
		
		if (commentsMatch)
			[model setSpotlightComments:comments];
		if (typesMatch)
			[model setType:type];
		if (creatorsMatch)
			[model setCreator:creator];
		
		desc = [descs objectAtIndex:0];
		[model setMultipleSelection:([descs count] > 1)];
		if (![model multipleSelection])
		{
			[model setName:[desc displayNameForRename]];
			
			// set data fork and rsrc for size if a file			
			if ([desc isFile])
			{
				[model setDataForkSize:[[NTSizeFormatter sharedInstance] fileSize:[desc dataForkSize]]]; 
				[model setRsrcForkSize:[[NTSizeFormatter sharedInstance] fileSize:[desc rsrcForkSize]]]; 
			}
		}
		
		// only set for first one, not sure how to do a mixed state for date, not a big deal anyway
		[model setCreationDate:[desc creationDate]];
		[model setModificationDate:[desc modificationDate]];
		
		// convert labelBits to selection array
		NSMutableArray* selectedLabels = [NSMutableArray array];
		int i, cnt=8;
		for (i=0;i<cnt;i++)
		{
			if ((labelBits & (1 << i)) == (1 << i))
				[selectedLabels addObject:[NSNumber numberWithInt:i]];
		}
		[model setSelectedLabels:selectedLabels];
		
		// set our result
		[self setModel:model];
	}
	
	return ![[self helper] killed];	
}

@end
