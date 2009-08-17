//
//  NTSizeCalculatorMgr.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTSizeCalculator, NTFSSize;

@interface NTSizeCalculatorMgr : NTSingletonObject 
{
	NSMutableDictionary* calculators;
	NSMutableDictionary* pendingAdditions;
	NSMutableDictionary* pendingRemovals;
	NSMutableDictionary* pendingUpdates;
	BOOL sentProcessAfterDelay;
	
	NSMutableDictionary* sizeCache;
}

@property (retain) NSMutableDictionary* calculators;
@property (retain) NSMutableDictionary* pendingAdditions;
@property (retain) NSMutableDictionary* pendingRemovals;
@property (retain) NSMutableDictionary* pendingUpdates;
@property (assign) BOOL sentProcessAfterDelay;
@property (retain, nonatomic) NSMutableDictionary* sizeCache;  // we do our own thread safety

- (void)addCalculator:(NTSizeCalculator*)calculator;
- (void)removeCalculator:(NTSizeCalculator*)calculator;

@end

@interface NTSizeCalculatorMgr (TreeNotifications)
- (void)folderSizeUpdated:(NTFileDesc*)folder size:(NTFSSize*)size;
@end

@interface NTSizeCalculatorMgr (SizeCache)
// keys are folder.dictionaryKey
- (NTFSSize*)sizeForKey:(NSString*)key;
- (void)setSize:(NTFSSize*)size forKey:(NSString*)key;
@end

