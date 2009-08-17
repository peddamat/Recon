//
//  NTListSizeCalculator.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFSSizeSpec, NTListSizeCalculator;

@protocol NTListSizeCalculatorDelegateProtocol <NSObject>
- (void)listSizeCalculatorUpdated:(NTListSizeCalculator*)sizeCalculator;
@end

@interface NTListSizeCalculator : NSObject
{
	id<NTListSizeCalculatorDelegateProtocol> delegate;
	NTFSSizeSpec* sizeSpec;
	NSNumber *uniqueID;
	NSArray *descs;
	NSMutableArray *calculators;
	
	NTFSSizeSpec* fileSizeSpec;
	NTThreadRunner* filesCalcThread;
}

@property (assign) id<NTListSizeCalculatorDelegateProtocol> delegate;  // not retained
@property (retain) NSNumber *uniqueID;
@property (retain) NTFSSizeSpec* sizeSpec;
@property (retain) NSArray *descs;
@property (retain) NSMutableArray *calculators;
@property (retain) NTThreadRunner* filesCalcThread;
@property (retain) NTFSSizeSpec* fileSizeSpec;

+ (NTListSizeCalculator*)calculator:(NSArray*)descs
					   delegate:(id<NTListSizeCalculatorDelegateProtocol>)delegate;
- (void)clearDelegate;
@end
