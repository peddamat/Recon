//
//  NTLabelsMenuItem.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 4/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTLabelsMenuItem.h"
#import "NTLabelsMenuView.h"
#import "NTLabelColorMgr.h"

#define kTopMargin 4
#define kVerticalMargin 0
#define kHorizontalMargin 20
#define kTextHeight 12
#define kSpaceBetween 2
#define kMenuViewSize 18

@interface NTLabelsMenuItem (Private)
- (void)buildViews;
@end

@implementation NTLabelsMenuItem

@synthesize labelViews;
@synthesize labelText;

+ (NSMenuItem*)menuItem:(SEL)theAction target:(id)theTarget;
{
	NSMenuItem *result = [[NSMenuItem alloc] initWithTitle:@"" action:theAction keyEquivalent:@""];
    [result setTarget:theTarget];
	[result setView:[[[NTLabelsMenuItem alloc] initWithFrame:NSMakeRect(0, 0, (8*(kMenuViewSize+kSpaceBetween))+(kHorizontalMargin*2), kMenuViewSize + kTextHeight + kTopMargin + (kVerticalMargin*2))] autorelease]];

	return [result autorelease];
}

- (void)commonInit;
{
	[self buildViews];
}

- (id)initWithFrame:(NSRect)frame;
{
	self = [super initWithFrame:frame];
	
	[self commonInit];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
	NSArray* subviews = [[[self subviews] copy] autorelease];
	[self removeAllSubviews];
	
	// don't want to save the subviews, we will rebuild when needed
	[super encodeWithCoder:aCoder];
	
	[self setSubviews:subviews];
}

- (id)initWithCoder:(NSCoder *)aDecoder;
{
	self = [super initWithCoder:aDecoder];
		
	[self commonInit];
	
	return self;
}

- (void)dealloc
{
	self.labelViews = nil;
    self.labelText = nil;
	[super dealloc];
}

- (void)updateWithState:(NSDictionary*)theState;
{
	int index=0;
	BOOL enabled = [theState boolForKey:@"enabled"];
	
	for (NTLabelsMenuView* view in self.labelViews)
	{
		int label = [[NTLabelColorMgr sharedInstance] labelAtIndex:index];

		NSNumber* labelState = [theState objectForKey:[NSNumber numberWithInt:label]];
		if (labelState)
		{
			if ([labelState intValue] == NSOnState)
				view.selected = YES;
			else
				view.selected = NO;
		}
		else
			view.selected = NO;
		
		view.enabled = enabled;
		
		[view setNeedsDisplay:YES];
		
		index++;
	}
}

- (void)updateLabelText:(NSString*)theText;
{	
	if ([theText length])
		self.labelText.stringValue = [NSString stringWithFormat:@"\"%@\"", theText];
	else
		self.labelText.stringValue = @""; // [NTLocalizedString localize:@"Label" table:@"menuBar"];
}

@end

@implementation NTLabelsMenuItem (Private)

- (void)buildViews;
{
	int i, cnt=8;
	NSRect rect, contentBounds;
	NSMutableArray *theViews = [NSMutableArray array];

	// subtract for state column
	contentBounds = NSInsetRect([self bounds], kHorizontalMargin, kVerticalMargin);
	contentBounds.size.height -= kTopMargin;
	
	NSRect remainder=contentBounds;

	self.labelViews = [NSMutableArray array];
	for (i=0;i<cnt;i++)
	{
		NSDivideRect(remainder, &rect, &remainder, kMenuViewSize, NSMinXEdge);
		rect.origin.y = NSMaxY(rect) - kMenuViewSize;
		rect.size.height = kMenuViewSize;
		
		NTLabelsMenuView* labelsView = [NTLabelsMenuView labelView:rect labelIndex:i];
		[theViews addObject:labelsView];
		[self addSubview:labelsView];
		
		// space between
		NSDivideRect(remainder, &rect, &remainder, kSpaceBetween, NSMinXEdge);
	}
	
	self.labelViews = [NSArray arrayWithArray:theViews];
	
	self.labelText = [NTStringView stringView:NSBackgroundStyleLight];
	self.labelText.alignment = NSCenterTextAlignment;
	self.labelText.font = [NSFont menuFontOfSize:10];
	self.labelText.textColor = [NSColor colorWithCalibratedWhite:.2 alpha:1.0];
	NSRect labelRect = contentBounds;
	labelRect.size.height = kTextHeight;
	[self.labelText setFrame:labelRect];
	[self addSubview:self.labelText];
}

@end
