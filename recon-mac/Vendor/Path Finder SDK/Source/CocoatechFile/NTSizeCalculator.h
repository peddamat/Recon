//
//  NTSizeCalculator.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFSSize, NTSizeCalculator;

@protocol NTSizeCalculatorDelegateProtocol <NSObject>
- (void)sizeCalculatorUpdated:(NTSizeCalculator*)sizeCalculator;
@end

@interface NTSizeCalculator : NSObject
{
	id<NTSizeCalculatorDelegateProtocol> delegate;
	NTFSSize* size;
	NSNumber *uniqueID;
	NTFileDesc *folder;
}

@property (assign) id<NTSizeCalculatorDelegateProtocol> delegate;  // not retained
@property (retain) NSNumber *uniqueID;
@property (retain) NTFSSize* size;
@property (retain) NTFileDesc *folder;

+ (NTSizeCalculator*)calculator:(NTFileDesc*)theFolder
					   delegate:(id<NTSizeCalculatorDelegateProtocol>)theDelegate;
- (void)clearDelegate;

// called from NTSizeCalculatorMgr when it's data is ready
- (void)setSizeAndNotifyDelegate:(NTFSSize*)theSize;
@end

@interface NTSizeCalculator (CacheAccess)
+ (NTFSSize*)calcSizeSync:(NTFileDesc*)theFolder;
+ (NTFSSize*)cachedSize:(NTFileDesc*)theFolder;

// debugging only
+ (void)debugTreeNodeForFolder:(NTFileDesc*)folder;
@end
