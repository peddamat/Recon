//
//  NTLabelsMenuView.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 4/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTLabelsMenuView : NSView <NSCoding> 
{
	BOOL enabled;
	NSInteger labelIndex;
	BOOL selected;
	NSTrackingArea* trackingArea;
	BOOL mouseInside;
}

@property (assign) BOOL enabled;
@property (assign) NSInteger labelIndex;
@property (assign) BOOL selected;
@property (retain) NSTrackingArea* trackingArea;
@property (assign) BOOL mouseInside;

+ (NTLabelsMenuView*)labelView:(NSRect)frame labelIndex:(NSInteger)theLabelIndex;
@end
