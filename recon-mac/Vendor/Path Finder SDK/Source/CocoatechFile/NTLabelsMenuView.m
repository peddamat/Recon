//
//  NTLabelsMenuView.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 4/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTLabelsMenuView.h"
#import "NTLabelColorMgr.h"
#import "NTLabelsMenuItem.h"

@interface NTLabelsMenuView (Private)
- (void)setupView;
- (NTLabelsMenuItem*)menuItemView;
@end

@implementation NTLabelsMenuView

@synthesize enabled;
@synthesize labelIndex;
@synthesize selected;
@synthesize trackingArea;
@synthesize mouseInside;

- (void)commonInit;
{
	[self setupView];
}

+ (NTLabelsMenuView*)labelView:(NSRect)frame labelIndex:(NSInteger)theLabelIndex;
{
	NTLabelsMenuView* result = [[NTLabelsMenuView alloc] initWithFrame:frame];
	
	result.labelIndex = theLabelIndex;
	[result commonInit];
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	self.trackingArea = nil;

    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
	[super encodeWithCoder:aCoder];
	
	[aCoder encodeInt:self.labelIndex forKey:@"labelIndex"];
	[aCoder encodeBool:self.enabled forKey:@"enabled"];
	[aCoder encodeBool:self.selected forKey:@"selected"];
	[aCoder encodeBool:self.mouseInside forKey:@"mouseInside"];
}

- (id)initWithCoder:(NSCoder *)aDecoder;
{
	self = [super initWithCoder:aDecoder];
	
	self.labelIndex = [aDecoder decodeIntForKey:@"labelIndex"];
	self.enabled = [aDecoder decodeBoolForKey:@"enabled"];
	self.selected = [aDecoder decodeBoolForKey:@"selected"];
	self.mouseInside = [aDecoder decodeBoolForKey:@"mouseInside"];

	[self commonInit];

	return self;
}

@end

@implementation NTLabelsMenuView (Private)

- (NTLabelsMenuItem*)menuItemView;
{
	return (NTLabelsMenuItem*)[self superview];
}

- (void)setupView;
{
	// determine the tracking options
	NSTrackingAreaOptions trackingOptions = (NSTrackingEnabledDuringMouseDrag |
											 NSTrackingMouseEnteredAndExited |
											 NSTrackingActiveInActiveApp |
											 NSTrackingActiveAlways);
	
	self.trackingArea = [[[NSTrackingArea alloc]
						  initWithRect:[self bounds]	
						  options: trackingOptions
						  owner: self
						  userInfo: nil] autorelease];
	
	[self addTrackingArea:self.trackingArea];
}

- (void)mouseEntered:(NSEvent*)event
{
	// which tracking area is being tracked?
	self.mouseInside = YES;
		
	[[self menuItemView] updateLabelText:[[NTLabelColorMgr sharedInstance] label:[[NTLabelColorMgr sharedInstance] labelAtIndex:self.labelIndex]]];
	
	[self setNeedsDisplay:YES];	// force update the currently tracked label back to its original color
}

- (void)mouseExited:(NSEvent*)event
{
	self.mouseInside = NO;
	
	[[self menuItemView] updateLabelText:@""];

	[self setNeedsDisplay:YES];	// force update the currently tracked label to a lighter color
}

- (void)mouseUp:(NSEvent*)event
{
	NSPoint mousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
	
	if (NSPointInRect(mousePoint, [self bounds]))
		[NSApp sendAction:[[self enclosingMenuItem] action] to:[[self enclosingMenuItem] target] from:[NSNumber numberWithInt:[[NTLabelColorMgr sharedInstance] labelAtIndex:self.labelIndex]]];
	
	// on mouse up, we want to dismiss the menu being tracked
	NSMenu* menu = [[self enclosingMenuItem] menu];
	[menu cancelTracking];
	
	[self setNeedsDisplay:YES];
}

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

- (void)drawRect:(NSRect)frame;
{	
	// tag is an index, not a label id
	int label = [[NTLabelColorMgr sharedInstance] labelAtIndex:self.labelIndex];
	
	NSColor *color = [[NTLabelColorMgr sharedInstance] color:label];
	if (color)
		[color set];
	else
		[[NSColor whiteColor] set];
	
	[NSBezierPath fillRect:NSInsetRect(frame, 2, 2)];
	
	BOOL isEnabled = [[self enclosingMenuItem] isEnabled] && self.enabled;
	BOOL isSelected = [[self enclosingMenuItem] isEnabled] && self.selected;
	BOOL isMouseInside = [[self enclosingMenuItem] isEnabled] && self.mouseInside;
	
	// if not enabled, draw over with white
	if (!isEnabled)
	{
		[[NSColor colorWithCalibratedWhite:1 alpha:.6] set];
		[NSBezierPath fillRect:NSInsetRect(frame, 2, 2)];
	}
	
	if (isSelected)
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
	
	if (isMouseInside)
	{
		[[NSColor keyboardFocusIndicatorColor] set];
		NSFrameRectWithWidth(frame, 2);
	}
}

@end
