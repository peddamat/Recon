//
//  NTAttributeModulePlugin.m
//  AttributeModulePlugin
//
//  Created by Steve Gehrman on 5/6/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTAttributeModulePlugin.h"
#import "NTAttributeUIController.h"

@interface NTAttributeModulePlugin (Private)
- (NTAttributeUIController *)UIController;
- (void)setUIController:(NTAttributeUIController *)theUIController;
@end

@interface NTAttributeModulePlugin (hidden)
- (void)setView:(NSView *)theView;
@end

@interface NTAttributeModulePlugin (Protocols) <NTModulePluginProtocol>
@end

@implementation NTAttributeModulePlugin

@synthesize host;

- (void)dealloc;
{
    [self setHost:nil];
	[self setView:nil];
    [self setUIController:nil];

    [super dealloc];
}

@end

@implementation NTAttributeModulePlugin (Protocols)

+ (id)plugin:(id<NTPathFinderPluginHostProtocol>)theHost;
{
    NTAttributeModulePlugin* result = [[self alloc] init];
	
	[result setHost:theHost];

    return [result autorelease];
}

	// return an NSMenuItem to be used in the plugins menu.  You can add a submenu to this item if you need more menu choices
	// be sure to implement - (BOOL)validateMenuItem:(NSMenuItem*)menuItem; in your menuItems target to enable/disable the menuItem
- (NSView*)view;
{
	if (!mView)
		[self setView:[[self UIController] view]];
	
	return mView;
}

- (void)setView:(NSView *)theView
{
    if (mView != theView)
    {
        [mView release];
        mView = [theView retain];
    }
}

- (NSMenu*)menu;
{
	return [[self UIController] menu];
}

- (void)browserEvent:(NTBrowserEventType)event browserID:(NSString*)theBrowserID;
{
	NSString* syncToBrowserID = [[self host] syncToBrowserID];
	if (syncToBrowserID && theBrowserID)
	{
		if (![syncToBrowserID isEqualToString:theBrowserID])
			return;  // if we are watching a certain browserID, and this one doesn't match, bail
	}
	
	BOOL resetSelection=NO;
	
	if ((event & kModuleWasHidden_browserEvent) == kModuleWasHidden_browserEvent)
		[[self UIController] selectionUpdated:nil];
	else
	{
		if ((event & kSelectionUpdated_browserEvent) == kSelectionUpdated_browserEvent)
			resetSelection = YES;
		if ((event & kContainingDirectoryUpdated_browserEvent) == kContainingDirectoryUpdated_browserEvent)
		{
			// if inspector mode, and no selection, set the containing directory
			if ([[self host] inspectorModule])
				resetSelection = YES;
		}
		
		if (resetSelection)
			[[self UIController] selectionUpdated:[[self UIController] selection]];
	}
}

@end

@implementation NTAttributeModulePlugin (Private)

//---------------------------------------------------------- 
//  UIController 
//---------------------------------------------------------- 
- (NTAttributeUIController *)UIController
{
	if (!mUIController)
		[self setUIController:[NTAttributeUIController controller:[self host]]];
	
    return mUIController; 
}

- (void)setUIController:(NTAttributeUIController *)theUIController
{
    if (mUIController != theUIController)
    {
		[mUIController invalidate];
		
        [mUIController release];
        mUIController = [theUIController retain];
    }
}

@end

