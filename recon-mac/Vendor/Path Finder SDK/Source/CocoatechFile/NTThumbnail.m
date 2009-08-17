//
//  NTThumbnail.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/15/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTThumbnail.h"
#import "NTFileTypeIdentifier.h"
#import "NTQuickLookThumbnail.h"

@interface NTThumbnail (Private)
- (void)setIsValid:(BOOL)flag;

- (CGImageRef)imageRef;
- (void)setImageRef:(CGImageRef)theImage;

- (void)drawImageInRect:(NSRect)drawRect;

- (void)createImageRefFromURL:(NSURL*)url maxSize:(NSSize)maxSize asIcon:(BOOL)asIcon;
@end

@implementation NTThumbnail

@synthesize frameStyle;
@synthesize image;
@synthesize size;

- (id)init;
{
	self = [super init];
	
	[self setIsValid:YES];
	
	return self;
}

+ (NTThumbnail*)invalidThumbnail;
{
	NTThumbnail *result = [[NTThumbnail alloc] init];
	
	[result setIsValid:NO];
	
	return [result autorelease];
}

+ (NTThumbnail*)thumbnailWithDesc:(NTFileDesc*)desc
						   asIcon:(BOOL)asIcon
						  maxSize:(NSSize)maxSize;
{
	NTThumbnail *result = nil;
	
	NTThumbnail *thumbnail = [[[NTThumbnail alloc] init] autorelease];
	
	[thumbnail createImageRefFromURL:[desc URL] maxSize:maxSize asIcon:asIcon];
	if ([thumbnail imageRef])			
	{			
		// set frame for pdfs
		if (!asIcon && [[desc typeIdentifier] isPDF])
			thumbnail.frameStyle = kNTThumbnailFrameStyle_normal;
		
		if (!NSEqualSizes(NSZeroSize, [thumbnail size]))
			result = thumbnail;
	}
	
	if (!result)
		result = [self invalidThumbnail];
	
	return result;
}

+ (NTThumbnail*)thumbnailWithImage:(NSImage*)image;
{
	NTThumbnail *result = nil;
	
	if (image)			
	{
		NSSize size = [image size];
		
		if (!NSEqualSizes(NSZeroSize, size))
		{			
			result = [[[NTThumbnail alloc] init] autorelease];
			
			[result setImage:image];
			[result setSize:size];
		}
	}
	
	if (!result)
		result = [self invalidThumbnail];
	
	return result;	
}

- (void)dealloc
{
    [self setImageRef:nil];
    self.image = nil;
    [super dealloc];
}

- (void)drawInRect:(NSRect)rect flipped:(BOOL)flipped;
{
	[self drawInRect:rect flipped:flipped selected:NO];
}

- (NSRect)imageRectForRect:(NSRect)rect;
{
	NSRect containerRect = NSZeroRect;
	containerRect.size = rect.size;
		
	// the max container rect, don't want to go bigger than the source image
	containerRect = [NTGeometry rect:containerRect centeredIn:rect scaleToFitContainer:YES];
	
	NSRect drawRect = NSZeroRect;
	drawRect.size = [self size];
	
	// image will get distorted if not the right rect, adjust and center rect before calling
	drawRect = [NTGeometry rect:drawRect centeredIn:containerRect scaleToFitContainer:YES canScaleLarger:NO];
	
	// avoid the fuzzies
	drawRect.origin.x = (int)drawRect.origin.x;
	drawRect.origin.y = (int)drawRect.origin.y;	
	
	return drawRect;
}	

- (NSShadow*)thumbnailShadow;
{
	// shared shadow
	static NSShadow *shadow = nil;
	
	if (!shadow)
		shadow = [[NSShadow shadowWithColor:[NSColor colorWithCalibratedWhite:0 alpha:.4] offset:NSMakeSize(-.5, -3) blurRadius:4] retain];
	
	return shadow;
}

- (void)drawInRect:(NSRect)rect
		   flipped:(BOOL)flipped
		  selected:(BOOL)selected;
{
	if (![self isValid])
		return;
	
	CGContextRef cgContext;
	
	cgContext = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
	
	if (flipped) 
	{
		CGContextSaveGState(cgContext);
		CGContextTranslateCTM(cgContext, 0.0f, rect.origin.y + rect.origin.y + rect.size.height);
		CGContextScaleCTM(cgContext, 1.0f, -1.0f);
	}
	
	NSRect drawRect = [self imageRectForRect:rect];
	
	// draw background	
	if (NSWidth(rect) > 48)
	{
		if (self.frameStyle == kNTThumbnailFrameStyle_shadow)
		{			
			// leave some room for the shadow
			drawRect.size.width -= 6;
			drawRect.size.height -= 6;
			if (flipped)
				drawRect.origin.y += 6;
			
			SGS;
			
			[[self thumbnailShadow] set];
			[[NSColor blackColor] set];
			[NSBezierPath fillRect:drawRect];
			
			RGS;
		}
	}
	
	// when selected, create a temporary image to create a darker image
	if (selected)
	{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		@try {
			static NSColor *sharedColor = nil;
			if (!sharedColor)
				sharedColor = [[NSColor colorWithCalibratedWhite:0 alpha:.5] retain];
			
			NSRect imageRect = drawRect;
			imageRect.origin = NSZeroPoint;
			
			NTImageMaker *imageMaker = [NTImageMaker maker:imageRect.size];
			[imageMaker lockFocus];
			{			
				[sharedColor set];
				NSRectFill(imageRect);
				
				SGS;
				{
					[[NSGraphicsContext currentContext] setCompositingOperation:NSCompositeDestinationAtop];
					[self drawImageInRect:imageRect];
				}
				RGS;
			}
			NSImage* selImage = [imageMaker unlockFocus];
			[selImage drawInRectHQ:drawRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		}
		@catch (NSException * e) {
			NSLog(@"%@", [e description]);
		}
		@finally {
			[pool release];
		}
	}
	else
		[self drawImageInRect:drawRect];
	
	if (self.frameStyle == kNTThumbnailFrameStyle_normal)
	{
		[[NSColor blackColor] set];
		NSFrameRectWithWidth(drawRect, .5);
	}	
	
	if (flipped)
		CGContextRestoreGState(cgContext);
}

- (NSImage*)convertToImage;
{
	if (![self isValid])
		return nil;
	
	NSImage *result = nil;
	
	if (!NSEqualSizes(NSZeroSize, self.size))
	{
		NSRect rect = NSZeroRect;
		rect.size = self.size;
		
		NTImageMaker* imageMaker = [NTImageMaker maker:self.size];
		
		[imageMaker lockFocus];
		[self drawInRect:rect flipped:NO];
		
		result = [imageMaker unlockFocus];
	}
	
	return result;
}

//---------------------------------------------------------- 
//  isValid 
//---------------------------------------------------------- 
- (BOOL)isValid
{
    return mv_isValid;
}

@end

@implementation NTThumbnail (Private)

- (void)drawImageInRect:(NSRect)drawRect;
{
	CGContextRef cgContext = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
	
	if ([self imageRef])
	{
		CGRect cgRect = CGRectMake(drawRect.origin.x, drawRect.origin.y, drawRect.size.width, drawRect.size.height);
		
		CGContextDrawImage(cgContext, cgRect, [self imageRef]);
	}
	else if ([self image])
		[[self image] drawInRectHQ:drawRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)setIsValid:(BOOL)flag
{
    mv_isValid = flag;
}

- (CGImageRef)imageRef
{
    return mv_imageRef; 
}

- (void)setImageRef:(CGImageRef)theImageRef
{
    if (mv_imageRef != theImageRef)
    {
        CGImageRelease(mv_imageRef);
        mv_imageRef = theImageRef;
    }
}

- (void)createImageRefFromURL:(NSURL*)url maxSize:(NSSize)maxSize asIcon:(BOOL)asIcon;
{	
	[self setImageRef:[[NTQuickLookThumbnail sharedInstance] previewImageRef:url ofSize:maxSize asIcon:asIcon]];
	
	if ([self imageRef])
		[self setSize:NSMakeSize(CGImageGetWidth([self imageRef]), CGImageGetHeight([self imageRef]))];
}

@end

