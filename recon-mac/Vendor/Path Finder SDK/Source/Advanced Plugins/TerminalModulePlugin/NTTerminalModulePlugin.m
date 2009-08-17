//
//  NTTerminalModulePlugin.m
//  TerminalModulePlugin
//
//  Created by Steve Gehrman on 5/6/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTTerminalModulePlugin.h"
#import <iTerm/iTerm.h>

@interface NTTerminalModulePlugin (Private)
- (id<NTPathFinderPluginHostProtocol>)host;
- (void)setHost:(id<NTPathFinderPluginHostProtocol>)theHost;

- (void)newTab:(id)sender;
- (NSString*)cdCommand;

- (ITTerminalView *)terminalView;
- (void)setTerminalView:(ITTerminalView *)theTerminalView;
@end

@interface NTTerminalModulePlugin (hidden)
- (void)setView:(NSView *)theView;
@end

@interface NTTerminalModulePlugin (Protocols) <NTModulePluginProtocol>
@end

@implementation NTTerminalModulePlugin

- (void)dealloc;
{
    [self setHost:nil];
	[self setView:nil];
    [self setTerminalView:nil];

    [super dealloc];
}

@end

@implementation NTTerminalModulePlugin (Protocols)

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
		// make sure this is initialized (yes goofy, I know)
		[iTermController sharedInstance];
		NSDictionary* dict = [[ITAddressBookMgr sharedInstance] defaultBookmarkData];
		[self setTerminalView:[ITTerminalView view:dict]];
		
		[self setView:[self terminalView]];
				
		[self newTab:nil];
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
	NSMenu* menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	NSMenuItem *menuItem;
		
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"New Tab" action:@selector(newTab:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self];
	[menu addItem:menuItem];
	
	id<NTFSItem> dir = [[self host] currentDirectory:[[self view] window] browserID:nil];
	if (dir)
	{		
		NSString* command = [NSString stringWithFormat:@"cd \"%@\"", [[dir path] stringByAbbreviatingWithTildeInPath]];
		
		menuItem = [[[NSMenuItem alloc] initWithTitle:command action:@selector(cdAction:) keyEquivalent:@""] autorelease];
		[menuItem setTarget:self];
		[menu addItem:menuItem];
	}
	
	return menu;
}

- (void)browserEvent:(NTBrowserEventType)event browserID:(NSString*)theBrowserID;
{
	if ((event & kSelectionUpdated_browserEvent) == kSelectionUpdated_browserEvent)
	{
	}
	if ((event & kContainingDirectoryUpdated_browserEvent) == kContainingDirectoryUpdated_browserEvent)
	{
	}
	if ((event & kModuleWasHidden_browserEvent) == kModuleWasHidden_browserEvent)
	{
	}
}

@end

@implementation NTTerminalModulePlugin (Private)

- (void)newTab:(id)sender;
{		
	NSDictionary* dict = [[ITAddressBookMgr sharedInstance] defaultBookmarkData];
	
	// must be in window, otherwise it's goofy
	[self performSelector:@selector(addSessionAfterDelay:) withObject:dict afterDelay:.25];
}

- (void)addSessionAfterDelay:(id)dict;
{
	[[self terminalView] addNewSession:dict withCommand:nil withURL:nil];
	
	NSString* command = [self cdCommand];
	if (command)
	{
		[[self terminalView] runCommand:command];	
		[[self terminalView] runCommand:@"clear"];	
	}
}

//---------------------------------------------------------- 
//  terminalView 
//---------------------------------------------------------- 
- (ITTerminalView *)terminalView
{
    return mTerminalView; 
}

- (void)setTerminalView:(ITTerminalView *)theTerminalView
{
    if (mTerminalView != theTerminalView)
    {
        [mTerminalView release];
        mTerminalView = [theTerminalView retain];
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

- (NSString*)cdCommand;
{
	id<NTFSItem> dir = [[self host] currentDirectory:[[self view] window] browserID:nil];
	
	if (dir)
	{
		NSString* path = [[dir path] stringWithShellCharactersEscaped:NO];
		
		return [NSString stringWithFormat:@"cd \"%@\"", path];
	}
	
	return nil;
}

@end

@implementation NTTerminalModulePlugin (Actions)

- (void)cdAction:(id)sender;
{
	NSString* command = [self cdCommand];
	
	if (command)
		[[self terminalView] runCommand:command];
}

@end
