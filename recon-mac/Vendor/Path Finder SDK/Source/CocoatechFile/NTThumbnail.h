//
//  NTThumbnail.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/15/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// like NSImage, but immutable
// no access to the embedded CGImageRef
// that way I don't have to worry about someone modifying an image return from my cache
// also uses the new thumbnail code in Tiger

typedef enum NTThumbnailFrameStyle {
	kNTThumbnailFrameStyle_none,
	kNTThumbnailFrameStyle_normal,
	kNTThumbnailFrameStyle_shadow,
} NTThumbnailFrameStyle;

@interface NTThumbnail : NSObject 
{
	BOOL mv_isValid;
	
	NTThumbnailFrameStyle frameStyle;  // frame set for non icon PDFs by default
	
	CGImageRef mv_imageRef;
	NSImage* image;
	NSSize size;
}

@property (assign) NTThumbnailFrameStyle frameStyle;
@property (retain) NSImage* image;
@property (assign) NSSize size;


+ (NTThumbnail*)thumbnailWithDesc:(NTFileDesc*)imageFile
						   asIcon:(BOOL)asIcon
						  maxSize:(NSSize)maxSize;

// size is the requested thumbnail size
// returns an invalid thumbnail if failed

+ (NTThumbnail*)thumbnailWithImage:(NSImage*)image;
// added as a convience for times you want to display thumbnails, but might also
// need to display existing images or a files icon
// you should always use initWithDesc for image files because it's optimal
// returns an invalid thumbnail if failed

+ (NTThumbnail*)invalidThumbnail;

- (BOOL)isValid;
- (NSRect)imageRectForRect:(NSRect)rect;

- (NSImage*)convertToImage; 
// converts to new NSImage

- (void)drawInRect:(NSRect)rect flipped:(BOOL)flipped;
- (void)drawInRect:(NSRect)rect flipped:(BOOL)flipped selected:(BOOL)selected;

- (void)drawInRect:(NSRect)rect
		   flipped:(BOOL)flipped
		  selected:(BOOL)selected;

@end
