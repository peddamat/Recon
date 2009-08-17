//
//  NTMenuPluginTutorial.m
//  MenuPluginTutorial
//
//  Created by Steve Gehrman on 3/19/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTMenuPluginTutorial.h"

@implementation NTMenuPluginTutorial

+ (id)plugin:(id<NTPathFinderPluginHostProtocol>)host;
{
    id result = [[self alloc] init];
	
	// normally you would want to retain the host to communicate with the application, but for this simple example we don't
	// [self setHost:host];
	
    return [result autorelease];
}

- (NSMenuItem*)contextualMenuItem;
{
	return [self menuItem];
}

- (NSMenuItem*)menuItem;
{
    NSMenuItem* menuItem;
	
    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Beep" action:@selector(pluginAction:) keyEquivalent:@""] autorelease];
    [menuItem setTarget:self];
	
    return menuItem;
}

- (void)pluginAction:(id)sender;
{
    // just beep, not very useful
	NSBeep();
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem;
{
    return YES;
}

// act directly on these items, not the current selection
- (id)processItems:(NSArray*)items parameter:(id)parameter;
{
    // do nothing
	return nil;	
}

@end
