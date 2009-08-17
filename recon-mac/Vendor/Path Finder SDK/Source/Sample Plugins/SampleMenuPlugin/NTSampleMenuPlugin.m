//
//  NTSampleMenuPlugin.m
//  Image Converter
//
//  Created by Steve Gehrman on Wed Mar 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NTSampleMenuPlugin.h"
#import "NTSampleMenuPluginWindowController.h"

@interface NTSampleMenuPlugin (Private)
- (id<NTPathFinderPluginHostProtocol>)host;
- (void)setHost:(id<NTPathFinderPluginHostProtocol>)theHost;
@end

@implementation NTSampleMenuPlugin

+ (id)plugin:(id<NTPathFinderPluginHostProtocol>)host;
{
    id result = [[self alloc] init];
	
	[result setHost:host];
	
    return [result autorelease];
}

- (void)dealloc;
{
    [self setHost:nil];
    [super dealloc];
}

- (NSMenuItem*)contextualMenuItem;
{
	return [self menuItem];
}

- (NSMenuItem*)menuItem;
{
    NSMenuItem* menuItem;

    menuItem = [[[NSMenuItem alloc] init] autorelease];
    [menuItem setTitle:@"Sample Menu Plugin"];
    [menuItem setAction:@selector(samplePluginAction:)];
    [menuItem setTarget:self];

    return menuItem;
}

// create a uniquely named action
- (void)samplePluginAction:(id)sender;
{
	[self processItems:nil parameter:nil];
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem;
{
    return YES;
}

// act directly on these items, not the current selection
- (id)processItems:(NSArray*)items parameter:(id)parameter;
{
	[NTSampleMenuPluginWindowController window:[self host]];
	
	return nil;
}

@end

@implementation NTSampleMenuPlugin (Private)

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




