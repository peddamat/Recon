//
//  NTiTunesModulePlugin.m
//  iTunesModulePlugin
//
//  Created by Steve Gehrman on 5/6/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTiTunesModulePlugin.h"
#import "NTiTunesUIController.h"

@interface NTiTunesModulePlugin (Private)
- (id<NTPathFinderPluginHostProtocol>)host;
- (void)setHost:(id<NTPathFinderPluginHostProtocol>)theHost;

- (NTiTunesUIController *)UIController;
- (void)setUIController:(NTiTunesUIController *)theUIController;
@end

@interface NTiTunesModulePlugin (hidden)
- (void)setView:(NSView *)theView;
@end

@interface NTiTunesModulePlugin (Protocols) <NTModulePluginProtocol>
@end

@implementation NTiTunesModulePlugin

- (void)dealloc;
{
    [self setHost:nil];
	[self setView:nil];
    [self setUIController:nil];

    [super dealloc];
}

@end

@implementation NTiTunesModulePlugin (Protocols)

+ (id)plugin:(id<NTPathFinderPluginHostProtocol>)host;
{
    id result = [[self alloc] init];
	
	[result setHost:host];
	[result UIController];  // loads ui
	
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
}

@end

@implementation NTiTunesModulePlugin (Private)

//---------------------------------------------------------- 
//  UIController 
//---------------------------------------------------------- 
- (NTiTunesUIController *)UIController
{
	if (!mUIController)
		[self setUIController:[NTiTunesUIController controller:[self host]]];
	
    return mUIController; 
}

- (void)setUIController:(NTiTunesUIController *)theUIController
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

