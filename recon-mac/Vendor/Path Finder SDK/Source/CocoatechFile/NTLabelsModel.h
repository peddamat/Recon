//
//  NTLabelsModel.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 6/21/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTLabelsModel : NSObject
{
	NSMutableDictionary* mDictionary;
	NSMutableDictionary* gradients;
	BOOL mSaveInProgress;
	
	unsigned mBuildID;
}

@property (retain) NSMutableDictionary* gradients;

+ (NTLabelsModel*)model;

- (unsigned)count;

- (NSMutableDictionary *)dictionary;

- (NSColor*)color:(int)label;
- (NTGradientDraw*)gradient:(int)label;
- (NSString*)name:(int)label;

- (unsigned)buildID;
- (void)restoreDefaults;


@end
