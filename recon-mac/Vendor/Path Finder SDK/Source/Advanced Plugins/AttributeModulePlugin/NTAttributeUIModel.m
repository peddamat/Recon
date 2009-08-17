//
//  NTAttributeUIModel.m
//  AttributeModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTAttributeUIModel.h"

@interface NTAttributeUIModel (Private)
- (NSArray *)keyPaths;
- (id)correctValue:(NSNumber*)value;

- (BOOL)observed;
- (void)setObserved:(BOOL)flag;
@end

@implementation NTAttributeUIModel

+ (NTAttributeUIModel*)model;
{
	NTAttributeUIModel* result = [[NTAttributeUIModel alloc] init];

	[result setLabels:[[NTLabelColorMgr sharedInstance] labelOrder]];
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setName:nil];
    [self setLabels:nil];
    [self setSelectedLabels:nil];
    [self setType:nil];
    [self setCreator:nil];
    [self setSpotlightComments:nil];
	[self setCreationDate:nil];
    [self setModificationDate:nil];
    [self setDataForkSize:nil];
    [self setRsrcForkSize:nil];

    [super dealloc];
}

//---------------------------------------------------------- 
//  name 
//---------------------------------------------------------- 
- (NSString *)name
{
    return mName; 
}

- (void)setName:(NSString *)theName
{
    if (mName != theName)
    {
        [mName release];
        mName = [theName retain];
    }
}

//---------------------------------------------------------- 
//  labels 
//---------------------------------------------------------- 
- (NSArray *)labels
{
    return mLabels;
}

- (void)setLabels:(NSArray *)theLabels
{
    if (mLabels != theLabels)
    {
        [mLabels release];
        mLabels = [theLabels retain];
    }
}

//---------------------------------------------------------- 
//  selectedLabels 
//---------------------------------------------------------- 
- (NSArray *)selectedLabels
{
	return mSelectedLabels; 
}

- (void)setSelectedLabels:(NSArray *)theSelectedLabels
{
    if (mSelectedLabels != theSelectedLabels)
    {		
        [mSelectedLabels release];
        mSelectedLabels = [theSelectedLabels retain];
    }
}

- (BOOL)validateSelectedLabels:(id *)ioValue error:(NSError **)outError
{
	if ([self initialized])
	{
		NSArray* new = (NSArray*) *ioValue;
		NSArray* old = mSelectedLabels;
		NSNumber* label;
		NSNumber* newSelection=nil;
		
		if ([new count] > [old count])
		{
			
			// item is new item, find the new item
			for (label in new)
			{
				if (![old containsObject:label])
				{
					newSelection = label;
					break;
				}
			}
		}
		else if ([new count] < [old count])
		{
			// item was deselected, find out which one
			
			// item is new item, find the new item
			for (label in old)
			{
				if (![new containsObject:label])
				{
					newSelection = label;
					break;
				}
			}			
		}
		else
			NSLog(@"shouldn't be here -[%@ %@]", [self className], NSStringFromSelector(_cmd));
		
		if (!newSelection)
			newSelection = [NSNumber numberWithInt:0];
		
		*ioValue = [NSArray arrayWithObject:newSelection];
	}
	
    return YES;
}

//---------------------------------------------------------- 
//  locked 
//---------------------------------------------------------- 
- (NSCellStateValue)locked
{
    return mLocked;
}

- (void)setLocked:(NSCellStateValue)theLocked
{
    mLocked = theLocked;
}

- (BOOL)validateLocked:(id *)ioValue error:(NSError **)outError
{
	*ioValue = [self correctValue:*ioValue];
	
    return YES;
}

//---------------------------------------------------------- 
//  invisible 
//---------------------------------------------------------- 
- (NSCellStateValue)invisible
{
    return mInvisible;
}

- (void)setInvisible:(NSCellStateValue)theInvisible
{
    mInvisible = theInvisible;
}

- (BOOL)validateInvisible:(id *)ioValue error:(NSError **)outError
{
	*ioValue = [self correctValue:*ioValue];
	
    return YES;
}

//---------------------------------------------------------- 
//  hideExtension 
//---------------------------------------------------------- 
- (NSCellStateValue)hideExtension
{
    return mHideExtension;
}

- (void)setHideExtension:(NSCellStateValue)theHideExtension
{
    mHideExtension = theHideExtension;
}

- (BOOL)validateHideExtension:(id *)ioValue error:(NSError **)outError
{
	*ioValue = [self correctValue:*ioValue];
	
    return YES;
}

//---------------------------------------------------------- 
//  stationeryPad 
//---------------------------------------------------------- 
- (NSCellStateValue)stationeryPad
{
    return mStationeryPad;
}

- (void)setStationeryPad:(NSCellStateValue)theStationeryPad
{
    mStationeryPad = theStationeryPad;
}

- (BOOL)validateStationeryPad:(id *)ioValue error:(NSError **)outError
{
	*ioValue = [self correctValue:*ioValue];
	
    return YES;
}

//---------------------------------------------------------- 
//  bundleBit 
//---------------------------------------------------------- 
- (NSCellStateValue)bundleBit
{
    return mBundleBit;
}

- (void)setBundleBit:(NSCellStateValue)theBundleBit
{
    mBundleBit = theBundleBit;
}

- (BOOL)validateBundleBit:(id *)ioValue error:(NSError **)outError
{
	*ioValue = [self correctValue:*ioValue];
	
    return YES;
}

//---------------------------------------------------------- 
//  aliasBit 
//---------------------------------------------------------- 
- (NSCellStateValue)aliasBit
{
    return mAliasBit;
}

- (void)setAliasBit:(NSCellStateValue)theAliasBit
{
    mAliasBit = theAliasBit;
}

- (BOOL)validateAliasBit:(id *)ioValue error:(NSError **)outError
{
	*ioValue = [self correctValue:*ioValue];
	
    return YES;
}

//---------------------------------------------------------- 
//  customIcon 
//---------------------------------------------------------- 
- (NSCellStateValue)customIcon
{
    return mCustomIcon;
}

- (void)setCustomIcon:(NSCellStateValue)theCustomIcon
{
    mCustomIcon = theCustomIcon;
}

- (BOOL)validateCustomIcon:(id *)ioValue error:(NSError **)outError
{
	*ioValue = [self correctValue:*ioValue];
	
    return YES;
}

//---------------------------------------------------------- 
//  type 
//---------------------------------------------------------- 
- (NSString *)type
{
    return mType; 
}

- (void)setType:(NSString *)theType
{
    if (mType != theType)
    {
        [mType release];
        mType = [theType retain];
    }
}

//---------------------------------------------------------- 
//  creator 
//---------------------------------------------------------- 
- (NSString *)creator
{
    return mCreator; 
}

- (void)setCreator:(NSString *)theCreator
{
    if (mCreator != theCreator)
    {
        [mCreator release];
        mCreator = [theCreator retain];
    }
}

//---------------------------------------------------------- 
//  spotlightComments 
//---------------------------------------------------------- 
- (NSString *)spotlightComments
{
    return mSpotlightComments; 
}

- (void)setSpotlightComments:(NSString *)theSpotlightComments
{
    if (mSpotlightComments != theSpotlightComments)
    {
        [mSpotlightComments release];
        mSpotlightComments = [theSpotlightComments retain];
    }
}

//---------------------------------------------------------- 
//  writable 
//---------------------------------------------------------- 
- (BOOL)writable
{
    return mWritable;
}

- (void)setWritable:(BOOL)flag
{
    mWritable = flag;
}

//---------------------------------------------------------- 
//  isFile 
//---------------------------------------------------------- 
- (BOOL)isFile
{
    return mIsFile;
}

- (void)setFile:(BOOL)flag
{
    mIsFile = flag;
}

//---------------------------------------------------------- 
//  multipleSelection 
//---------------------------------------------------------- 
- (BOOL)multipleSelection
{
    return mMultipleSelection;
}

- (void)setMultipleSelection:(BOOL)flag
{
    mMultipleSelection = flag;
}

//---------------------------------------------------------- 
//  initialized 
//---------------------------------------------------------- 
- (BOOL)initialized
{
    return mInitialized;
}

- (void)setInitialized:(BOOL)flag
{
    mInitialized = flag;
}

//---------------------------------------------------------- 
//  creationDate 
//---------------------------------------------------------- 
- (NSDate *)creationDate
{
    return mCreationDate; 
}

- (void)setCreationDate:(NSDate *)theCreationDate
{
    if (mCreationDate != theCreationDate)
    {
        [mCreationDate release];
        mCreationDate = [theCreationDate retain];
    }
}

//---------------------------------------------------------- 
//  modificationDate 
//---------------------------------------------------------- 
- (NSDate *)modificationDate
{
    return mModificationDate; 
}

- (void)setModificationDate:(NSDate *)theModificationDate
{
    if (mModificationDate != theModificationDate)
    {
        [mModificationDate release];
        mModificationDate = [theModificationDate retain];
    }
}

//---------------------------------------------------------- 
//  dataForkSize 
//---------------------------------------------------------- 
- (NSString *)dataForkSize
{
    return mDataForkSize; 
}

- (void)setDataForkSize:(NSString *)theDataForkSize
{
    if (mDataForkSize != theDataForkSize)
    {
        [mDataForkSize release];
        mDataForkSize = [theDataForkSize retain];
    }
}

//---------------------------------------------------------- 
//  rsrcForkSize 
//---------------------------------------------------------- 
- (NSString *)rsrcForkSize
{
    return mRsrcForkSize; 
}

- (void)setRsrcForkSize:(NSString *)theRsrcForkSize
{
    if (mRsrcForkSize != theRsrcForkSize)
    {
        [mRsrcForkSize release];
        mRsrcForkSize = [theRsrcForkSize retain];
    }
}

- (void)startObserving:(id)observer;
{
	[self setObserved:YES];
	
	NSEnumerator *e = [[self keyPaths] objectEnumerator];
	NSString *thisKey;
	
	while (thisKey = [e nextObject])
	{
		[self addObserver:observer
			   forKeyPath:thisKey
				  options:NSKeyValueObservingOptionOld
				  context:NULL];
	}
}

- (void)stopObserving:(id)observer
{
	if ([self observed])
	{
		[self setObserved:NO];
		
		NSEnumerator *e = [[self keyPaths] objectEnumerator];
		NSString *thisKey;
		
		while (thisKey = [e nextObject])
		{
			[self removeObserver:observer forKeyPath:thisKey];
		}
	}
}

@end

@implementation NTAttributeUIModel (Private)

//---------------------------------------------------------- 
//  observed 
//---------------------------------------------------------- 
- (BOOL)observed
{
    return mObserved;
}

- (void)setObserved:(BOOL)flag
{
    mObserved = flag;
}

- (NSArray *)keyPaths
{
    NSArray *result = [NSArray arrayWithObjects:
        @"name",
        @"labels",
        @"selectedLabels",
        @"locked",
        @"invisible",
        @"hideExtension",
        @"stationeryPad",
        @"bundleBit",
        @"aliasBit",
        @"customIcon",
        @"type",
        @"creator",
        @"spotlightComments",
        @"creationDate",
        @"modificationDate",
        @"dataForkSize",
        @"rsrcForkSize",
        nil];
	
    return result;
}

// very lame hack, had to avoid mixed state, very stupid
- (id)correctValue:(NSNumber*)value;
{
	if ([self initialized])
	{
		NSCellStateValue state = [value intValue];
		if (state == NSMixedState)
			value = [NSNumber numberWithBool:YES];
	}	
	
	return value;
}

@end

