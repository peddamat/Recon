//
//  NTiTunesToolbarView.m
//  iTunesModulePlugin
//
//  Created by Steve Gehrman on 4/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTiTunesToolbarView.h"

@implementation NTiTunesToolbarView

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
    [super dealloc];
}

- (void)drawRect:(NSRect)rect;
{
	[super drawRect:rect];
	
	[[NTGradientDraw sharedDarkHeaderGradient:[[self window] dimControls]] drawInRect:rect horizontal:YES flipped:[self isFlipped]];
	
	NSRect line = [self bounds];
	line.size.height = 1;
	[[NTStandardColors frameColor:[[self window] dimControls]] set];
	[NSBezierPath fillRect:line];
}

@end
