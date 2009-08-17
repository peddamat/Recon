//
//  NTiTunesUIView.m
//  iTunesModulePlugin
//
//  Created by Steve Gehrman on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTiTunesUIView.h"

@implementation NTiTunesUIView

- (void)drawRect:(NSRect)rect;
{
	[[NSColor windowBackgroundColor] set];
	[NSBezierPath fillRect:rect];
}

- (BOOL)isOpaque;
{
	return YES;
}

- (BOOL)isFlipped;
{
    return YES;
}

- (void)awakeFromNib;
{
    // must flip all the coordinates, this keeps things flush to topleft if resized
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
