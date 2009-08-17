//
//  NTImageSizeMenuPlugin.m
//  ImageSizeMenuPlugin
//
//  Created by Steve Gehrman on Wed Mar 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NTImageSizeMenuPlugin.h"

@interface NTImageSizeMenuPlugin (Private)
- (BOOL)isImageSelected;

- (id<NTPathFinderPluginHostProtocol>)host;
- (void)setHost:(id<NTPathFinderPluginHostProtocol>)theHost;
@end

@interface NTImageSizeMenuPlugin (Protocols) <NSMenuDelegate>
@end

@implementation NTImageSizeMenuPlugin

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
	if ([self isImageSelected])
	{
		NSMenuItem *result = [[[NSMenuItem alloc] initWithTitle:[NTLocalizedString localize:@"Image Size" table:@"menuBar"] action:0 keyEquivalent:@""] autorelease];
		NSMenu* submenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
		
		[submenu setDelegate:self];  // builds dynamically
		
		[result setSubmenu:submenu];
		
		return result;
	}
	
	return nil;
}

- (IBAction)itemSizeMenuItemAction:(id)sender;
{
	if ([sender isKindOfClass:[NSMenuItem class]])
	{
		NSString* sizeString = [sender representedObject];
		
		if ([sizeString isKindOfClass:[NSString class]])
		{
			[[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
			[[NSPasteboard generalPasteboard] setString:sizeString forType:NSStringPboardType];
		}
	}
}


- (BOOL)validateMenuItem:(NSMenuItem*)menuItem;
{
    return YES;
}

- (id)processItems:(NSArray*)items parameter:(id)parameter;
{
	return nil;
}

@end

@implementation NTImageSizeMenuPlugin (Private)

- (BOOL)isImageSelected;
{
	NSArray* selection = [[self host] selection:nil browserID:nil];
    NTFileDesc* desc;
	
    for (desc in selection)
    {
		
        if ([desc isValid] && [desc isFile] && [[desc typeIdentifier] isImage])
            return YES;
    }
    
    return NO;
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

@implementation NTImageSizeMenuPlugin (Protocols)

// NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu*)menu;
{
	if (![menu numberOfItems])
	{
		NSMenuItem *menuItem;
		NSEnumerator* enumerator = [[[self host] selection:nil browserID:nil] objectEnumerator];
		NTFileDesc* desc;
		int count=0;
		
		while (desc = [enumerator nextObject])
		{
			if ([[desc typeIdentifier] isImageForPreview])
			{
				NSSize imageSize = [[desc metadata] imageSizeMD];
				
				// not sure why, some images don't have meta data set?  See thumbnails folder in the iPhoto directories
				if (NSEqualSizes(NSZeroSize, imageSize))
					imageSize = [NTCGImage imageSize:desc];
				
				if (!NSEqualSizes(NSZeroSize, imageSize))
				{
					int dpi = [[desc metadata] imageDPIMD].height; // just showing height?
					NSString* menuTitle;
					
					if (dpi)
						menuTitle = [NSString stringWithFormat:@"%@: %dw x %dh (%d dpi)", [desc displayName], (int)imageSize.width, (int)imageSize.height, dpi];
					else
						menuTitle = [NSString stringWithFormat:@"%@: %dw x %dh", [desc displayName], (int)imageSize.width, (int)imageSize.height];
					
					menuItem = [[[NSMenuItem alloc] init] autorelease];
					[menuItem setTitle:menuTitle];
					[menuItem setAction:@selector(itemSizeMenuItemAction:)];
					[menuItem setTarget:self];
					[menuItem setRepresentedObject:[NSString stringWithFormat:@"width=\"%d\" height=\"%d\"", (int)imageSize.width, (int)imageSize.height]];
					
					[menu addItem:menuItem];
					
					// max is 20
					if (++count > 20)
						break;
				}
			}
		}
		
		if (![menu numberOfItems])
		{
			menuItem = [[[NSMenuItem alloc] init] autorelease];
			[menuItem setTitle:@"None"];
			[menuItem setEnabled:NO];
			[menu addItem:menuItem];			
		}
		
		[menu setFontSize:kSmallMenuFontSize color:nil];
	}
}

@end


