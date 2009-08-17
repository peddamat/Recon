//
//  NTLabelColorMgr.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Tue Feb 19 2002.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NTLabelColorMgr.h"
#import "NTLabelsModel.h"
#import "NTLabelLazyMenu.h"

@interface NTLabelColorMgr (Private)
- (NSMenu*)makeLabelMenu:(BOOL)forMenuBar fontSize:(int)fontSize;
- (int)labelRank:(int)label;

- (NTLabelsModel *)labelsModel;
- (void)setLabelsModel:(NTLabelsModel *)theLabelsModel;
@end

@interface NTLabelColorMgr (hidden)
- (void)setLabelMenu:(NTLabelLazyMenu *)theLabelMenu;

- (void)setLabelOrder:(NSArray *)theLabelOrder;

- (void)setSmallLabelMenu:(NTLabelLazyMenu *)theSmallLabelMenu;
@end

@implementation NTLabelColorMgr

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

- (id)init;
{
	self = [super init];
	
	[self setLabelsModel:[NTLabelsModel model]];

	return self;
}

- (void)dealloc;
{
    [self setLabelsModel:nil];
	[self setLabelMenu:nil];
    [self setSmallLabelMenu:nil];
	[self setLabelOrder:nil];
	
    [super dealloc];
}

// order is red(6), orange(7), yellow(5), green(2), blue(4), purple(3), gray(1)
- (NSComparisonResult)compare:(int)label1 label2:(int)label2;
{
    if (label1 == label2)
        return NSOrderedSame;
        
    return ([self labelRank:label1] < [self labelRank:label2]) ? NSOrderedDescending : NSOrderedAscending;
}

- (NSDictionary*)dictionary; // used for bindings
{
    return [[self labelsModel] dictionary];
}

// labels are 1-7, 0 is none and returns nil
- (NSColor*)color:(int)label;
{
    return [[self labelsModel] color:label];
}

// labels are 1-7, 0 is none and returns nil
- (NTGradientDraw*)gradient:(int)label;
{
    return [[self labelsModel] gradient:label];
}

// labels are 1-7, 0 is none and returns nil
- (NSString*)label:(int)label;
{
	NSString* result = [[self labelsModel] name:label];
	
	// avoid acceptions building menu
	if (!result)
		result = @"";
	
    return result;
}

- (NSMenu*)labelPopUpMenu;
{
    return [self makeLabelMenu:NO fontSize:kDefaultMenuFontSize];
}

//---------------------------------------------------------- 
//  labelMenu 
//---------------------------------------------------------- 
- (NTLabelLazyMenu *)labelMenu
{
	if (!mLabelMenu)
	{
		[self setLabelMenu:(NTLabelLazyMenu*)[NTLabelLazyMenu lazyMenu:[NTLocalizedString localize:@"Labels" table:@"menuBar"] target:nil action:@selector(labelAction:)]];
		[[self labelMenu] setFontSize:kDefaultMenuFontSize];
	}
	
    return mLabelMenu; 
}

- (void)setLabelMenu:(NTLabelLazyMenu *)theLabelMenu
{
    if (mLabelMenu != theLabelMenu) {
        [mLabelMenu release];
        mLabelMenu = [theLabelMenu retain];
    }
}

//---------------------------------------------------------- 
//  smallLabelMenu 
//---------------------------------------------------------- 
- (NTLabelLazyMenu *)smallLabelMenu
{
	if (!mSmallLabelMenu)
	{
		[self setSmallLabelMenu:(NTLabelLazyMenu*)[NTLabelLazyMenu lazyMenu:[NTLocalizedString localize:@"Labels" table:@"menuBar"] target:nil action:@selector(labelAction:)]];
		[[self smallLabelMenu] setFontSize:kSmallMenuFontSize];
	}
	
    return mSmallLabelMenu; 
}

- (void)setSmallLabelMenu:(NTLabelLazyMenu *)theSmallLabelMenu
{
    if (mSmallLabelMenu != theSmallLabelMenu) {
        [mSmallLabelMenu release];
        mSmallLabelMenu = [theSmallLabelMenu retain];
    }
}

- (unsigned)buildID;
{
	return [[self labelsModel] buildID];
}

- (int)labelAtIndex:(int)index;
{
	if (index < [[self labelOrder] count])
		return [[[self labelOrder] objectAtIndex:index] intValue];
	
	return 0;
}

- (int)indexForLabel:(int)label;
{
	NSInteger result = [[self labelOrder] indexOfObject:[NSNumber numberWithInt:label]];
	
	if (result == NSNotFound)
		result = 0;
	
	return result;
}

//---------------------------------------------------------- 
//  labelOrder 
//---------------------------------------------------------- 
- (NSArray *)labelOrder
{
	if (!mLabelOrder)
	{
		[self setLabelOrder:[NSArray arrayWithObjects:
			[NSNumber numberWithInt:0],
			[NSNumber numberWithInt:6],
			[NSNumber numberWithInt:7],
			[NSNumber numberWithInt:5],
			[NSNumber numberWithInt:2],
			[NSNumber numberWithInt:4],
			[NSNumber numberWithInt:3],
			[NSNumber numberWithInt:1],
			nil]];
	}
	
    return mLabelOrder; 
}

- (void)setLabelOrder:(NSArray *)theLabelOrder
{
    if (mLabelOrder != theLabelOrder) {
        [mLabelOrder release];
        mLabelOrder = [theLabelOrder retain];
    }
}

- (void)buildLabelsMenu:(NSMenu*)menu fontSize:(int)fontSize action:(SEL)action;
{
	[menu removeAllMenuItems];
	
    NSMenuItem* item;
	
    // build in the proper order
	NSEnumerator *enumerator = [[self labelOrder] objectEnumerator];
	NSNumber *labelNumber;
	
	// first item is 0, pass this, we add none below
	[enumerator nextObject];
	
	while (labelNumber = [enumerator nextObject])
    {        
        item = [[[NSMenuItem alloc] init] autorelease];
        [item setTitle:[self label:[labelNumber intValue]]];
		[item setImage:[NSMenu menuColorImage:[self color:[labelNumber intValue]]]];
		[item setRepresentedObject:labelNumber];
		[item setAction:action];
		[item setTarget:nil];
		[item setFontSize:fontSize color:nil];
		
        [menu addItem:item];
    }
	
	// add a separator
	[menu insertItem:[NSMenuItem separatorItem] atIndex:0];
    
    // add the None choice
    item = [[[NSMenuItem alloc] init] autorelease];
    [item setTitle:[NTLocalizedString localize:@"None" table:@"menuBar"]];
	
	[item setFontSize:fontSize color:nil];
	
    // create an image filled with the color
    NTImageMaker* image = [NTImageMaker maker:NSMakeSize(16, 12)];
    [image lockFocus];
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:NSMakeRect(0, 0, 16, 12)];
    [[NSColor lightGrayColor] set];
    NSFrameRect(NSMakeRect(0, 0, 16, 12));
    [item setImage:[image unlockFocus]];
	
	[item setRepresentedObject:[NSNumber numberWithInt:0]];
	[item setAction:action];
	[item setTarget:nil];
    [menu insertItem:item atIndex:0];	
}

- (void)restoreDefaults;
{
	[[self labelsModel] restoreDefaults];
}

@end

@implementation NTLabelColorMgr (Private)

//---------------------------------------------------------- 
//  labelsModel 
//---------------------------------------------------------- 
- (NTLabelsModel *)labelsModel
{
    return mLabelsModel; 
}

- (void)setLabelsModel:(NTLabelsModel *)theLabelsModel
{
    if (mLabelsModel != theLabelsModel) {
        [mLabelsModel release];
        mLabelsModel = [theLabelsModel retain];
    }
}

- (NSMenu*)makeLabelMenu:(BOOL)forMenuBar fontSize:(int)fontSize;
{
    NSMenu* menu = [[[NSMenu alloc] init] autorelease];
    NSMenuItem* item;
    int i, x, cnt = MIN(7, [[self labelsModel] count]); // safety since we have the order array below

    // build in the proper order
    int order[7] = {6,7,5,2,4,3,1};
    for (x=cnt-1;x>=0;x--)
    {
        i = order[x]-1;
        
        item = [[[NSMenuItem alloc] init] autorelease];
        [item setTitle:[self label:i+1]];

		[item setImage:[NSMenu menuColorImage:[self color:i+1]]];
        
        if (forMenuBar)
        {
            [item setRepresentedObject:[NSNumber numberWithInt:i+1]];
            
            [item setAction:@selector(labelAction:)];
            [item setTarget:nil];
        }
        else
            [item setTag:i+1];  // tags like kDynamicMenuItemTag are reserved in the menu bar (lame, I know)

		if (fontSize)
			[item setFontSize:fontSize color:nil];
		
        [menu insertItem:item atIndex:0];
    }

    if (forMenuBar)
    {
        // add a separator
        [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
    }
    
    // add the None choice
    item = [[[NSMenuItem alloc] init] autorelease];
    [item setTitle:[NTLocalizedString localize:@"None" table:@"menuBar"]];
		
	if (fontSize)
		[item setFontSize:fontSize color:nil];

    // create an image filled with the color
    NTImageMaker* image = [NTImageMaker maker:NSMakeSize(16, 12)];
    [image lockFocus];
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:NSMakeRect(0, 0, 16, 12)];
    [[NSColor lightGrayColor] set];
    NSFrameRect(NSMakeRect(0, 0, 16, 12));
    [item setImage:[image unlockFocus]];

    if (forMenuBar)
    {
        [item setRepresentedObject:[NSNumber numberWithInt:0]];
        
        [item setAction:@selector(labelAction:)];
        [item setTarget:nil];
    }
    else
        [item setTag:0];
    
    [menu insertItem:item atIndex:0];

    return menu;
}

- (int)labelRank:(int)label;
{
    int result = 0;
    
    // sort order is red(6), orange(7), yellow(5), green(2), blue(4), purple(3), gray(1)
    switch (label)
    {
        case 6:
            result = 10;
            break;
        case 7:
            result = 9;
            break;
        case 5:
            result = 8;
            break;
        case 2:
            result = 7;
            break;            
        case 4:
            result = 6;
            break;
        case 3:
            result = 5;
            break;
        case 1:
            result = 4;
            break;
    }
    
    return result;
}

@end
