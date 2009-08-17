//
//  NTOpenWithModulePlugin.m
//  OpenWithModulePlugin
//
//  Created by Steve Gehrman on 5/6/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTOpenWithModulePlugin.h"
#import "NTOpenWithUIController.h"

@interface NTOpenWithModulePlugin (Private)
- (id<NTPathFinderPluginHostProtocol>)host;
- (void)setHost:(id<NTPathFinderPluginHostProtocol>)theHost;

- (NTOpenWithUIController *)UIController;
- (void)setUIController:(NTOpenWithUIController *)theUIController;
@end

@interface NTOpenWithModulePlugin (hidden)
- (void)setView:(NSView *)theView;
@end

@interface NTOpenWithModulePlugin (Protocols) <NTModulePluginProtocol>
@end

@implementation NTOpenWithModulePlugin

- (void)dealloc;
{
    [self setHost:nil];
	[self setView:nil];
    [self setUIController:nil];

    [super dealloc];
}

@end

@implementation NTOpenWithModulePlugin (Protocols)

+ (id)plugin:(id<NTPathFinderPluginHostProtocol>)host;
{
    id result = [[self alloc] init];
	
	[result setHost:host];
	
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
	return nil;
}

- (void)browserEvent:(NTBrowserEventType)event browserID:(NSString*)theBrowserID;
{
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
		{
			NSArray* selection = [[self host] selection:[[self view] window] browserID:nil];
			if (![selection count])
			{
				if ([[self host] inspectorModule])
				{
					NTFileDesc *dir = (NTFileDesc*) [[self host] currentDirectory:[[self view] window] browserID:nil];
					
					if (dir)
						selection = [NSArray arrayWithObject:dir];
				}
			}
			
			[[self UIController] selectionUpdated:selection];
		}
	}
}

@end

@implementation NTOpenWithModulePlugin (Private)

//---------------------------------------------------------- 
//  UIController 
//---------------------------------------------------------- 
- (NTOpenWithUIController *)UIController
{
	if (!mUIController)
		[self setUIController:[NTOpenWithUIController controller:[self host]]];
	
    return mUIController; 
}

- (void)setUIController:(NTOpenWithUIController *)theUIController
{
    if (mUIController != theUIController)
    {
		[mUIController invalidate];
		
        [mUIController release];
        mUIController = [theUIController retain];
    }
}

//---------------------------------------------------------- 
//  host 
//---------------------------------------------------------- 
- (id<NTPathFinderPluginHostProtocol>)host
{
    return mHost; 
}

- (void)setHost:(id<NTPathFinderPluginHostProtocol>)theHost
{
    if (mHost != theHost)
    {
        [mHost release];
        mHost = [theHost retain];
    }
}

@end

