//
//  NTQuickLookThumbnail.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 12/4/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTQuickLookThumbnail.h"
#import <QuickLook/QuickLook.h>

@interface NTQuickLookThumbnail (Private)
- (NSDictionary *)iconOptions;
- (void)setIconOptions:(NSDictionary *)theIconOptions;
@end

@implementation NTQuickLookThumbnail

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

- (id)init;
{
	self = [super init];
	
	// set now to avoid thread safety issues
	[self setIconOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] 
													 forKey:(NSString *)kQLThumbnailOptionIconModeKey]];
	
	return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setIconOptions:nil];
    [super dealloc];
}

// called from thread
- (NSImage *)previewImage:(NSURL*)url
				   ofSize:(NSSize)size
				   asIcon:(BOOL)icon;
{
	NSImage *result=nil;
	
    CGImageRef ref = [self previewImageRef:url ofSize:size asIcon:icon];
    if (ref) 
	{
        NSBitmapImageRep *bitmapImageRep = [[[NSBitmapImageRep alloc] initWithCGImage:ref] autorelease];
		
        if (bitmapImageRep) 
		{
            result = [[[NSImage alloc] initWithSize:[bitmapImageRep size]] autorelease];
            [result addRepresentation:bitmapImageRep];
        }
		
        CFRelease(ref);
    }
	
    return result;
}

// called from thread
- (CGImageRef)previewImageRef:(NSURL*)url
					   ofSize:(NSSize)size
					   asIcon:(BOOL)icon;
{
	// not sure why, but it fails for less than 24, images seem to work for any size
	// movies seemed to work for 18, PDFS needed 24
	static const int minDimension = 24;

	CGSize cgSize;
	cgSize.width = MAX(minDimension, size.width);
	cgSize.height = MAX(minDimension, size.height);
	
	CGImageRef result=nil;
	@try {
		result = QLThumbnailImageCreate(kCFAllocatorDefault, 
												   (CFURLRef)url, 
												   cgSize,
												   (CFDictionaryRef) ((icon) ? [self iconOptions] : nil));
	}
	@catch (NSException * e) {
		NSLog(@"QLThumbnailImageCreate exception: %@", [e description]);
	}
	@finally {
	}
		
    return result;
}

@end

@implementation NTQuickLookThumbnail (Private)

//---------------------------------------------------------- 
//  iconOptions 
//---------------------------------------------------------- 
- (NSDictionary *)iconOptions
{
    return mIconOptions; 
}

- (void)setIconOptions:(NSDictionary *)theIconOptions
{
    if (mIconOptions != theIconOptions)
    {
        [mIconOptions release];
        mIconOptions = [theIconOptions retain];
    }
}

@end

