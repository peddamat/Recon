//
//  NTLabelButtonMatrix.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 6/22/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTLabelButtonMatrix.h"
#import "NTLabelColorMgr.h"

@interface NTLabelButtonMatrix (Private)
- (NSTextField *)textField;
- (void)setTextField:(NSTextField *)theTextField;
- (void)addCellTrackingRect:(NSRect)cellRect userData:(NSCell*)cell assumeInside:(BOOL)mouseInsideNow;

- (NSMutableArray *)trackingAreas;
- (void)setTrackingAreas:(NSMutableArray *)theTrackingAreas;

- (void)highlightCell:(NSCell*)cell;
@end

@implementation NTLabelButtonMatrix

- (void)awakeFromNib;
{	
	[self setTextField:[[self superview] viewWithTag:55555]];
	[[self textField] setStringValue:@""];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	[self setTextField:nil];
	[self setTrackingAreas:nil];

    [super dealloc];
}

@end

@implementation NTLabelButtonMatrix (Private)

- (void)removeTrackingAreas;
{
	for (NSTrackingArea* area in [self trackingAreas])
		[self removeTrackingArea:area];
	
	[self setTrackingAreas:nil];
}

//---------------------------------------------------------- 
//  trackingAreas 
//---------------------------------------------------------- 
- (NSMutableArray *)trackingAreas
{
	if (!mTrackingAreas)
		[self setTrackingAreas:[NSMutableArray array]];
	
    return mTrackingAreas; 
}

- (void)setTrackingAreas:(NSMutableArray *)theTrackingAreas
{
    if (mTrackingAreas != theTrackingAreas)
    {
        [mTrackingAreas release];
        mTrackingAreas = [theTrackingAreas retain];
    }
}

- (void)addCellTrackingRect:(NSRect)cellRect userData:(NSCell*)cell assumeInside:(BOOL)mouseInsideNow;
{    
	unsigned options = NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingActiveInKeyWindow;
		
	if (mouseInsideNow)
		options |= NSTrackingAssumeInside;
	
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:cellRect 
														options:options
														  owner:self
													   userInfo:[NSDictionary dictionaryWithObject:cell forKey:@"cell"]];
    [self addTrackingArea:area];
	[[self trackingAreas] addObject:area];
	
    [area release];
}

//---------------------------------------------------------- 
//  textField 
//---------------------------------------------------------- 
- (NSTextField *)textField
{
    return mTextField; 
}

- (void)setTextField:(NSTextField *)theTextField
{
    if (mTextField != theTextField) {
        [mTextField release];
        mTextField = [theTextField retain];
    }
}

- (void)updateTrackingAreas;
{	
	[self removeTrackingAreas];
	
	NSPoint mouse = [NSEvent mouseLocation];
	mouse = [[self window] convertScreenToBase:mouse];
	mouse = [self convertPoint:mouse fromView:nil];
	
	NSEnumerator *enumerator = [[self cells] objectEnumerator];
	NSCell *cell;
	NSCell* highlightCell = nil;
	
	while (cell = [enumerator nextObject])
	{		
		NSRect cellRect = NSInsetRect([self rectOfCell:cell], 1, 1);
		BOOL mouseInsideNow = NSMouseInRect(mouse, cellRect, [self isFlipped]);

		if (mouseInsideNow)
			highlightCell = cell;
		
		[self addCellTrackingRect:cellRect userData:cell assumeInside:mouseInsideNow];
	}
		
	// make sure we remove our over state before we destroy the cursor rect
	[self highlightCell:highlightCell];
}

- (void)highlightCell:(NSCell*)inCell;
{
	NSEnumerator *enumerator = [[self cells] objectEnumerator];
	NSCell *cell;
	
	while (cell = [enumerator nextObject])
		[cell setHighlighted:(cell == inCell)];		
	
	[self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)theEvent;
{
	if ([self isEnabled])
	{
		// SNG fucked up with bindings, must do by hand
		// [super mouseDown:theEvent];
		
		NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];

		NSCell* cell = [self cellAtPoint:point];
		[cell trackMouse:theEvent inRect:[self rectOfCell:cell] ofView:self untilMouseUp:YES];
	}
}

- (void)rightMouseDown:(NSEvent *)theEvent;
{
	if ([self isEnabled])
		[super rightMouseDown:theEvent];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	NSButtonCell* cell = [(NSDictionary*)[theEvent userData] objectForKey:@"cell"];

	if ([self isEnabled])
	{
		[cell setHighlighted:YES];
				
		NSString* label = [[NTLabelColorMgr sharedInstance] label:[[NTLabelColorMgr sharedInstance] labelAtIndex:[cell tag]]];
		
		if (![label length])
			label = @"";
		else
			label = [NSString stringWithFormat:@"\"%@\"", label];
		
		[[self textField] setStringValue:label];
		[[self textField] setNeedsDisplay:YES];
		
		[self setNeedsDisplay:YES];
	}
}

- (void)mouseExited:(NSEvent *)theEvent
{	
	NSButtonCell* cell = [(NSDictionary*)[theEvent userData] objectForKey:@"cell"];

	if ([self isEnabled])
	{
		[[self textField] setStringValue:@""];
		[[self textField] setNeedsDisplay:YES];
		
		[cell setHighlighted:NO];
		[self setNeedsDisplay:YES];
	}
}

@end
