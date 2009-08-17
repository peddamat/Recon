//
//  NTSampleModulePlugin.m
//  SampleModulePlugin
//
//  Created by Steve Gehrman on 5/6/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTSampleModulePlugin.h"
#import "NTSampleUIController.h"

@interface NTSampleModulePlugin (Private)
- (id<NTPathFinderPluginHostProtocol>)host;
- (void)setHost:(id<NTPathFinderPluginHostProtocol>)theHost;

- (NTSampleUIController *)UIController;
- (void)setUIController:(NTSampleUIController *)theUIController;
@end

@interface NTSampleModulePlugin (hidden)
- (void)setView:(NSView *)theView;
@end

@interface NTSampleModulePlugin (Protocols) <NTModulePluginProtocol>
@end

@implementation NTSampleModulePlugin

- (void)dealloc;
{
    [self setHost:nil];
	[self setView:nil];
    [self setUIController:nil];

    [super dealloc];
}

@end

@implementation NTSampleModulePlugin (Protocols)

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
			;
		
		if (resetSelection)
			[[self UIController] selectionUpdated:[[self host] selection:[[self view] window] browserID:nil]];
	}
}

@end

@implementation NTSampleModulePlugin (Private)

//---------------------------------------------------------- 
//  UIController 
//---------------------------------------------------------- 
- (NTSampleUIController *)UIController
{
	if (!mUIController)
		[self setUIController:[NTSampleUIController controller]];
	
    return mUIController; 
}

- (void)setUIController:(NTSampleUIController *)theUIController
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

