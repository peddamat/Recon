//
//  NTLabelButtonCell.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 6/22/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTLabelButtonCell.h"
#import "NTLabelColorMgr.h"

@implementation NTLabelButtonCell

- (NSImage*)sharedStopImage:(NSSize)size;
{
	static NSImage* shared=nil;
	
	if (!shared)
	{
		NSRect rect = NSZeroRect;
		rect.size = size;
		
		shared = [[NSImage stopInteriorImage:rect lineColor:[NSColor grayColor]] retain];
	}
	
	return shared;
}

- (void)drawImage:(NSImage*)image withFrame:(NSRect)frame inView:(NSView*)controlView;
{
	BOOL enabled = [(NSMatrix*)controlView isEnabled];
	
	// tag is an index, not a label id
	int label = [[NTLabelColorMgr sharedInstance] labelAtIndex:[self tag]];
	
	NSColor *color = [[NTLabelColorMgr sharedInstance] color:label];
	if (color)
		[color set];
	else
		[[NSColor whiteColor] set];
	
	[NSBezierPath fillRect:NSInsetRect(frame, 2, 2)];
	
	// if not enabled, draw over with white
	if (!enabled)
	{
		[[NSColor colorWithCalibratedWhite:1 alpha:.6] set];
		[NSBezierPath fillRect:NSInsetRect(frame, 2, 2)];
	}
	
	if ([self state] == NSOnState)
	{
		[[NSColor blackColor] set];
		NSFrameRectWithWidth(frame, 2);
	}
	else
	{
		[[NSColor grayColor] set];
		NSFrameRectWithWidth(NSInsetRect(frame, 2, 2), 1);
	}
	
	if (!color)
	{
		NSRect imageRect = NSInsetRect(frame, 3, 3);
		
		imageRect = [NTGeometry rect:imageRect centeredIn:frame scaleToFitContainer:NO];
		
		[[self sharedStopImage:imageRect.size] drawInRectHQ:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
	}
	
	if ([self isHighlighted])
	{
		[[NSColor keyboardFocusIndicatorColor] set];
		NSFrameRectWithWidth(frame, 2);
	}
}

- (NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView;
{
	return NSZeroRect;	
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView*)controlView;
{
}

@end
