//
//  NTAttributeUIModel.h
//  AttributeModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTAttributeUIModel : NSObject 
{
	BOOL mInitialized;
	BOOL mObserved;  // YES if startObserving is called

	NSString* mName;
	
	// for labels matrix
	NSArray *mLabels;
	NSArray *mSelectedLabels;
	
	NSCellStateValue mLocked;
	NSCellStateValue mInvisible;
	NSCellStateValue mHideExtension;
	NSCellStateValue mStationeryPad;
	NSCellStateValue mBundleBit;
	NSCellStateValue mAliasBit;
	NSCellStateValue mCustomIcon;
	
	NSString* mType;
	NSString* mCreator;

	NSString* mSpotlightComments;
	
	NSDate* mCreationDate;
	NSDate* mModificationDate;
	
	NSString* mDataForkSize;
	NSString* mRsrcForkSize;
	
	// used for enabling/disabling
	BOOL mWritable;
	BOOL mIsFile;
	BOOL mMultipleSelection;
}

+ (NTAttributeUIModel*)model;

- (void)startObserving:(id)observer;
- (void)stopObserving:(id)observer;

- (NSString *)name;
- (void)setName:(NSString *)theName;

- (NSArray *)labels;
- (void)setLabels:(NSArray *)theLabels;

- (NSArray *)selectedLabels;
- (void)setSelectedLabels:(NSArray *)theSelectedLabels;

- (NSCellStateValue)locked;
- (void)setLocked:(NSCellStateValue)theLocked;

- (NSCellStateValue)invisible;
- (void)setInvisible:(NSCellStateValue)theInvisible;

- (NSCellStateValue)hideExtension;
- (void)setHideExtension:(NSCellStateValue)theHideExtension;

- (NSCellStateValue)stationeryPad;
- (void)setStationeryPad:(NSCellStateValue)theStationeryPad;

- (NSCellStateValue)bundleBit;
- (void)setBundleBit:(NSCellStateValue)theBundleBit;

- (NSCellStateValue)aliasBit;
- (void)setAliasBit:(NSCellStateValue)theAliasBit;

- (NSCellStateValue)customIcon;
- (void)setCustomIcon:(NSCellStateValue)theCustomIcon;

- (NSString *)type;
- (void)setType:(NSString *)theType;

- (NSString *)creator;
- (void)setCreator:(NSString *)theCreator;

- (NSString *)spotlightComments;
- (void)setSpotlightComments:(NSString *)theSpotlightComments;

- (NSDate *)creationDate;
- (void)setCreationDate:(NSDate *)theCreationDate;

- (NSDate *)modificationDate;
- (void)setModificationDate:(NSDate *)theModificationDate;

- (NSString *)dataForkSize;
- (void)setDataForkSize:(NSString *)theDataForkSize;

- (NSString *)rsrcForkSize;
- (void)setRsrcForkSize:(NSString *)theRsrcForkSize;

// enabling/disabling bindings

- (BOOL)initialized;
- (void)setInitialized:(BOOL)flag;

- (BOOL)writable;
- (void)setWritable:(BOOL)flag;

- (BOOL)isFile;
- (void)setFile:(BOOL)flag;

- (BOOL)multipleSelection;
- (void)setMultipleSelection:(BOOL)flag;

@end
