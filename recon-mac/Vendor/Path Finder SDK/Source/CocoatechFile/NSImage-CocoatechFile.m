//
//  NSImage-Extensions.m
//  CocoatechFile
//
//  Created by sgehrman on Fri Oct 12 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NSImage-CocoatechFile.h"
#import "NTIconCompositor.h"
#import "NTIcon.h"
#import "NTFileTypeIdentifier.h"
#import "NTResourceMgr.h"
#import "NTQuickLookThumbnail.h"

@interface NSImage (CocoatechFile_Private)
+ (NSImage*)PICTResourceImage:(NTFileDesc*)desc;
@end

@implementation NSImage (CocoatechFile)

+ (NSImage *)imageForSystemType:(OSType)iconType size:(int)size;
{
    return [NSImage imageForType:iconType creator:kSystemIconsCreator size:size];
}

+ (NSImage *)imageForType:(OSType)iconType creator:(OSType)creator size:(int)size;
{
    NSImage* result=nil;
    OSStatus err;
    IconRef iconRef;

    err = GetIconRef(kOnSystemDisk, creator, iconType, &iconRef);
    if (err == noErr)
    {
        result = [NSImage iconRef:iconRef toImage:size];

        err = ReleaseIconRef(iconRef);
    }

    return result;
}

+ (NSImage *)imageForDesc:(NTFileDesc*)desc size:(int)size;
{
    NSImage* result=nil;
    OSStatus err;
    IconRef iconRef;
    SInt16 outLabel;

    err = GetIconRefFromFileInfo([desc FSRefPtr],
                                 0,
                                 NULL,
                                 0,
                                 NULL,
                                 kIconServicesNormalUsageFlag,
                                 &iconRef,
                                 &outLabel);

    if (err == noErr)
    {
        result = [NSImage iconRef:iconRef toImage:size];

        // Docs don't mention having to release it, but I verified that you do
        err = ReleaseIconRef(iconRef);
    }

    return result;
}

+ (NSImage*)iconRef:(IconRef)iconRef toImage:(int)size
{
    return [NSImage iconRef:iconRef toImage:size select:NO];
}

+ (NSImage*)iconRef:(IconRef)iconRef toImage:(int)size select:(BOOL)select;
{
    return [NSImage iconRef:iconRef toImage:size label:0 select:select];
}

+ (NSImage*)iconRef:(IconRef)iconRef toImage:(int)size label:(int)label select:(BOOL)select;
{
    return [NSImage iconRef:iconRef toImage:size label:label select:select alpha:1.0];
}

+ (NSImage*)iconRef:(IconRef)iconRef toImage:(int)size label:(int)label select:(BOOL)select alpha:(float)alpha;
{
	return [NSImage iconRef:iconRef toImage:size label:label select:select alpha:1.0 alignment:kAlignAbsoluteCenter];
}

+ (NSImage*)iconRef:(IconRef)iconRef
			toImage:(int)size 
			  label:(int)label 
			 select:(BOOL)select
			  alpha:(float)alpha
		  alignment:(int)alignment;
{
	NTImageMaker* maker = [NTImageMaker maker:NSMakeSize(size,size)];

    [maker lockFocus];
    [NTIconCompositor drawIconForRef:iconRef inRect:NSMakeRect(0,0,size,size) label:label selected:select opened:NO flip:NO alpha:alpha alignment:alignment];
	return [maker unlockFocus];
}

+ (NSImage*)iconRef:(IconRef)iconRef toImage:(int)size label:(int)label highlight:(BOOL)highlight; // used when clicking on an image button
{
    NSImage* original = [self iconRef:iconRef toImage:size label:label select:NO];
	
	NTImageMaker* maker = [NTImageMaker maker:NSMakeSize(size,size)];
	
    [maker lockFocus];
    
    [original compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
    
    [[[NSColor blackColor] colorWithAlphaComponent:.5] set];
    NSRectFillUsingOperation(NSMakeRect(0,0,size,size) ,NSCompositeSourceAtop);
	
	return [maker unlockFocus];    
}

// creates an image with 32 and 24 bitmapimagereps, if you don't do the bitmapimagerep stuff, you get cachedimagereps which don't scale right for some reason.
+ (NSImage*)iconRefToToolbarImage:(IconRef)iconRef;
{
	return [self iconRefForToolbar:iconRef label:0 select:NO];
}

+ (NSImage*)iconRefForToolbar:(IconRef)iconRef label:(int)label select:(BOOL)select;
{
    NSImage* result;
    NSBitmapImageRep* bitmapImageRep32, *bitmapImageRep24;
    NSRect rect32 = NSMakeRect(0,0,32,32);
    NSRect rect24 = NSMakeRect(0,0,24,24);

	// get 32 bitmap
	NTImageMaker* imageMaker = [NTImageMaker maker:rect32.size];
    [imageMaker lockFocus];    
    [NTIconCompositor drawIconForRef:iconRef inRect:rect32 label:label selected:select opened:NO flip:NO];
	[imageMaker unlockFocus];
	bitmapImageRep32 = [imageMaker imageRep];

	// get 24 bitmap
	imageMaker = [NTImageMaker maker:rect24.size];
    [imageMaker lockFocus];
    [NTIconCompositor drawIconForRef:iconRef inRect:rect24 label:label selected:select opened:NO flip:NO];
	[imageMaker unlockFocus];
	bitmapImageRep24 = [imageMaker imageRep];
	
	// create result image
    result = [[[NSImage alloc] initWithSize:NSMakeSize(32,32)] autorelease];
    [result addRepresentation:bitmapImageRep32];
    [result addRepresentation:bitmapImageRep24];
    [result setDataRetained:YES];  // retain the bitmap so if we are scaled we still look good
    [result setScalesWhenResized:YES];

    return result;
}

// creates an image with 32, and 24 bitmapimagereps, if you don't do the bitmapimagerep stuff, you get cachedimagereps which don't scale right for some reason.
+ (NSImage*)imageToToolbarImage:(NSImage*)image;
{
    NSImage* result;

    result = [[[NSImage alloc] initWithSize:NSMakeSize(32,32)] autorelease];

    [result addRepresentation:[image bitmapImageRepForSize:32]];
    [result addRepresentation:[image bitmapImageRepForSize:24]];

    return result;
}

// add a badge to an image, badge added to all imageReps
- (NSImage*)imageWithBadge:(NTIcon*)icon;
{
    NSImage* result = [[[NSImage alloc] initWithSize:[self size]] autorelease];
    NSArray* reps = [self representations];
    NSImageRep *rep;
    NSImage *badgeImage, *srcImage, *newImage;
    
    for (rep in reps)
    {
                
        NSRect imageRect = NSMakeRect(0,0,[rep size].width, [rep size].height);
        
        badgeImage = [icon imageForSize:imageRect.size.width label:0 select:NO alpha:1.0 alignment:kAlignNone];
        srcImage = [self sizeIcon:imageRect.size.width];
        newImage = [[[NSImage alloc] initWithSize:imageRect.size] autorelease];
        
        [newImage lockFocus];
        [srcImage drawInRect:imageRect fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
        [badgeImage drawInRect:imageRect fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
        [newImage unlockFocus];
        
        rep = [[newImage representations] objectAtIndex:0];
        rep = [[rep copy] autorelease];

        [result addRepresentation:rep];
    }
    
    return result;
}

- (NSImage*)imageWithBadge:(NTIcon*)icon badgeSize:(int)badgeSize badgeOffset:(NSPoint)offset fraction:(float)fraction;
{
	NSImage* badgeImage = [icon imageForSize:badgeSize label:0 select:NO];
    NTImageMaker* result = [NTImageMaker maker:[self size]];

	[result lockFocus];
	
    [self compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
    [badgeImage compositeToPoint:offset operation:NSCompositeSourceOver fraction:fraction];
	
	return [result unlockFocus];
}

// call from thread, could be slow
+ (NSImage*)imageFromNonImageFile:(NTFileDesc*)desc maxSize:(NSSize)maxSize asIcon:(BOOL)asIcon;
{
	NSImage* image = nil;
	
	// too slow over a network
	if (![desc isNetwork])
	{
		image = [self quickLookPreviewImage:desc 
									 ofSize:maxSize
									 asIcon:asIcon];
		
		if (!image)
			image = [self PICTResourceImage:desc];
	}
	
	if (!image)
	{
		int theSize = MIN(maxSize.width, maxSize.height);
						
		theSize = MIN([[desc icon] maxSizeAvailable], theSize);
		
		image = [NSImage iconRef:[[desc icon] iconRef] toImage:theSize];
	}
	
	return image;	
}

// called from thread
+ (NSImage *)quickLookPreviewImage:(NTFileDesc*)desc
							ofSize:(NSSize)size
							asIcon:(BOOL)icon;
{
	return [[NTQuickLookThumbnail sharedInstance] previewImage:[desc URL]
											   ofSize:size
											   asIcon:icon];
}

@end

@implementation NSImage (CocoatechFile_Private)

+ (NSImage*)PICTResourceImage:(NTFileDesc*)desc;
{
    if ([desc isFile] && ![desc isApplication])
    {
        if ([desc rsrcForkSize] > 0)
        {
            NTResourceMgr *mgr = [NTResourceMgr mgrWithDesc:desc];
            NSData* pictData = [mgr resourceForType:'PICT'];
            
            if (pictData)
            {
                NSImage* pictImage = [[[NSImage alloc] initWithData:pictData] autorelease];
                
                return pictImage;
            }
        }
    }
    
    return nil;
}

@end

