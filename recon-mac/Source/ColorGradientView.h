//
//  ColorGradientView.h
//  recon
//
//  Created by Sumanth Peddamatham on 8/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
// Thanks: http://www.katoemba.net/makesnosenseatall/tag/nsgradient/

#import <Cocoa/Cocoa.h>


@interface ColorGradientView : NSView
{
   NSColor *startingColor;
   NSColor *endingColor;
   int angle;
}

// Define the variables as properties
@property(nonatomic, retain) NSColor *startingColor;
@property(nonatomic, retain) NSColor *endingColor;
@property(assign) int angle;

@end

