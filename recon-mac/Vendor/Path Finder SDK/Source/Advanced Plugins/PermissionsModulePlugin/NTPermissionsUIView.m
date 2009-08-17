//
//  NTPermissionsUIView.m
//  PermissionsModulePlugin
//
//  Created by Steve Gehrman on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTPermissionsUIView.h"


@implementation NTPermissionsUIView

- (void)drawRect:(NSRect)rect;
{
	if ([self drawsBackground])
	{
		[[NSColor whiteColor] set];
		[NSBezierPath fillRect:rect];
	}
}

- (BOOL)isOpaque;
{
	if ([self drawsBackground])
		return YES;
	
	return NO;
}

//---------------------------------------------------------- 
//  drawsBackground 
//---------------------------------------------------------- 
- (BOOL)drawsBackground
{
    return mDrawsBackground;
}

- (void)setDrawsBackground:(BOOL)flag
{
    mDrawsBackground = flag;
}

- (BOOL)isFlipped;
{
    return YES;
}

- (void)awakeFromNib;
{
    // must flip all the coordinates
    NSEnumerator* enumerator = [[self subviews] objectEnumerator];
    NSView* view;
    NSRect frame, bounds = [self bounds];
    
    while (view = [enumerator nextObject])
    {
        frame = [view frame];
        
        frame.origin.y = NSHeight(bounds) - frame.origin.y;
        frame.origin.y -= NSHeight(frame);
        
        [view setFrame:frame];
    }
}

@end
