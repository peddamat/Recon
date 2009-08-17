//
//  NTPermissionsModulePlugin.m
//  PermissionsModulePlugin
//
//  Created by Steve Gehrman on 5/6/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTPermissionsModulePlugin.h"
#import "NTPermissionsUIController.h"

@interface NTPermissionsModulePlugin (Private)
- (NTPermissionsUIController *)UIController;
- (void)setUIController:(NTPermissionsUIController *)theUIController;
@end

@interface NTPermissionsModulePlugin (hidden)
- (void)setView:(NSView *)theView;
@end

@interface NTPermissionsModulePlugin (Protocols) <NTModulePluginProtocol>
@end

@implementation NTPermissionsModulePlugin

@synthesize host;

- (void)dealloc;
{
    [self setHost:nil];
	[self setView:nil];
    [self setUIController:nil];

    [super dealloc];
}

@end

@implementation NTPermissionsModulePlugin (Protocols)

+ (id)plugin:(id<NTPathFinderPluginHostProtocol>)theHost;
{
    NTPermissionsModulePlugin* result = [[self alloc] init];
	
	[result setHost:theHost];
		
    return [result autorelease];
}

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
		{
			NSArray* selection = [[self host] selection:[[self view] window] browserID:syncToBrowserID];
			if (![selection count])
			{
				if ([[self host] inspectorModule])
				{
					NTFileDesc *dir = (NTFileDesc*) [[self host] currentDirectory:[[self view] window] browserID:syncToBrowserID];
					
					if (dir)
						selection = [NSArray arrayWithObject:dir];
				}
			}
			
			[[self UIController] selectionUpdated:selection];
		}
	}
}

@end

@implementation NTPermissionsModulePlugin (Private)

//---------------------------------------------------------- 
//  UIController 
//---------------------------------------------------------- 
- (NTPermissionsUIController *)UIController
{
	if (!mUIController)
		[self setUIController:[NTPermissionsUIController controller:[self host]]];
	
    return mUIController; 
}

- (void)setUIController:(NTPermissionsUIController *)theUIController
{
    if (mUIController != theUIController)
    {
		[mUIController invalidate];
		
        [mUIController release];
        mUIController = [theUIController retain];
    }
}

@end

