//
//  NTModulePluginTutorial.m
//  ModulePluginTutorial
//
//  Created by Steve Gehrman on 3/19/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTModulePluginTutorial.h"

@interface NTModulePluginTutorial (hidden)
- (void)setView:(NSView *)theView;
@end

@interface NTModulePluginTutorial (Private)
- (id<NTPathFinderPluginHostProtocol>)host;
- (void)setHost:(id<NTPathFinderPluginHostProtocol>)theHost;
@end

@implementation NTModulePluginTutorial

- (void)dealloc;
{
	[self setHost:nil];
	[self setView:nil];
	
    [super dealloc];
}

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
	{
		NSTextField* view = [[[NSTextField alloc] initWithFrame:NSMakeRect(0,0,10,10)] autorelease];
		[view setStringValue:@"hello world"];
		
		[self setView:view];
	}
	
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

- (void)browserEvent:(NTBrowserEventType)event;
{	
	if ((event & kModuleWasHidden_browserEvent) == kModuleWasHidden_browserEvent)
	{
		// stop a playing movie or clear the view, we are not visible in the UI
	}
	else
	{
		if ((event & kSelectionUpdated_browserEvent) == kSelectionUpdated_browserEvent)
		{
			// selection changed, update view
		}
		if ((event & kContainingDirectoryUpdated_browserEvent) == kContainingDirectoryUpdated_browserEvent)
		{
			// containing directory changed, update view
		}
		
		NSArray* selection = [[self host] selection:[[self view] window]];
		id<NTFSItem> currentDirectory = [[self host] currentDirectory:[[self view] window]];
		
		[(NSTextField*)[self view] setStringValue:[NSString stringWithFormat:@"selection:%@\ncurrent directory:%@", [selection description], [currentDirectory description]]];
	}
}

@end

@implementation NTModulePluginTutorial (Private)

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


