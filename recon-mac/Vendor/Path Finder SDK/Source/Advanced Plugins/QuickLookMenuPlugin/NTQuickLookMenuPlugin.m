//
//  NTQuicklookMenuPlugin.m
//  QuicklookMenuPlugin
//
//  Created by Steve Gehrman on 3/19/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTQuicklookMenuPlugin.h"
#import "NTQuickLook.h"
#import "NTQuickLookSL.h"

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5
#define NTQUICKLOOKCLASS NTQuickLook
#else
#define NTQUICKLOOKCLASS NTQuickLookSL
#endif

@implementation NTQuicklookMenuPlugin

@synthesize host;

+ (id)plugin:(id<NTPathFinderPluginHostProtocol>)host;
{
	NTQuicklookMenuPlugin* result = [[self alloc] init];
	
	result.host = host;
	[[result host] setUpdateMenuPluginForEvents:YES];
	
	[[NTQUICKLOOKCLASS sharedInstance] setDelegate:result];

	return [result autorelease];
}

- (void)dealloc;
{
	[[NTQUICKLOOKCLASS sharedInstance] setDelegate:nil];

	self.host = nil;
	
	[super dealloc];
}

- (NSMenuItem*)contextualMenuItem;
{
	return [self menuItem];
}

- (NSMenuItem*)menuItem;
{
    NSMenuItem* menuItem;
	
	// Use bundle name that is already localized (uses displayName to get this)
	NSString* title = [[[NSBundle bundleForClass:[self class]] localizedInfoDictionary] objectForKey:(id)kCFBundleNameKey];
    menuItem = [[[NSMenuItem alloc] initWithTitle:title action:@selector(pluginAction:) keyEquivalent:@""] autorelease];
    [menuItem setTarget:self];
	
    return menuItem;
}

- (void)pluginAction:(id)sender;
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
	BOOL toggleWindow = YES;
	BOOL fullScreen=NO;

	if (parameter)
	{
		toggleWindow = [[parameter objectForKey:@"toggleWindow"] boolValue];
		fullScreen = [[parameter objectForKey:@"fullScreen"] boolValue];
	}
	
	if (toggleWindow && [[NTQUICKLOOKCLASS sharedInstance] isOpen])
		[[NTQUICKLOOKCLASS sharedInstance] close];
	else if (toggleWindow || [[NTQUICKLOOKCLASS sharedInstance] isOpen])
	{
		id<NTFSItem> desc;
		BOOL zoomEffect=NO;

		if (!items)
		{
			items = [[self host] selection:nil browserID:nil];
			
			if ([items count])
				zoomEffect = YES;
		}
		
		if (![items count])
		{			
			desc = [[self host] currentDirectory:nil browserID:nil];
			if (desc)
				items = [NSArray arrayWithObject:desc];
		}
		
		NSMutableArray* urls = [NSMutableArray array];
		NSURL* url;
		
		for (desc in items)
		{
			url = [[desc descResolveIfAlias] URL];  // might be Computer which will return nil as URL
			if (url)
				[urls addObject:url];  // resolving aliases
		}
		
		if ([urls count])
			[[NTQUICKLOOKCLASS sharedInstance] showURLs:urls 
						 zoomEffect:zoomEffect
						 fullScreen:fullScreen];
	}
	
	return nil;
}

@end

@implementation NTQuicklookMenuPlugin (QuicklookDelegate)

- (NSRect)previewPanel:(NSPanel*)panel frameForURL:(NSURL*)URL
{
	NSRect result = [[self host] frameForItem:[[self host] newFSItem:[URL path]] window:nil browserID:nil];
	
	// added as a hack to handle close button animation.
	if (NSIsEmptyRect(result))
	{
		result = [[NTQUICKLOOKCLASS sharedInstance] windowFrame];
		
		result = NSInsetRect(result, NSWidth(result)/2, NSHeight(result)/2);
	}
	
	return result;
}

@end

