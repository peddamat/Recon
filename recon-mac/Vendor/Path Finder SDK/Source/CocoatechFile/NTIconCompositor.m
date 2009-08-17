//
//  NTIconCompositor.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Wed Aug 14 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import "NTIconCompositor.h"
#import <Carbon/Carbon.h>
#import "NTIcon.h"
#import "NTLabelColorMgr.h"
#import "NTIconStore.h"

@interface NTIconCompositor (Private)
+ (void)drawLabelColor:(NSColor*)labelColor inRect:(NSRect)rect flip:(BOOL)flip;
@end

@implementation NTIconCompositor

+ (void)drawIconFor:(NTFileDesc*)desc inRect:(NSRect)rect drawLabel:(BOOL)drawLabel flip:(BOOL)flip;
{
    [NTIconCompositor drawIconFor:desc inRect:rect selected:NO opened:NO drawLabel:(BOOL)drawLabel flip:flip];
}

+ (void)drawIconFor:(NTFileDesc*)desc inRect:(NSRect)rect selected:(BOOL)selected opened:(BOOL)opened drawLabel:(BOOL)drawLabel flip:(BOOL)flip;
{
    [NTIconCompositor drawIconForRef:[[desc icon] iconRef] inRect:rect label:(drawLabel) ? [desc label]:0 selected:selected opened:opened flip:flip];
}

+ (void)drawIconForRef:(IconRef)iconRef inRect:(NSRect)rect label:(int)label selected:(BOOL)selected opened:(BOOL)opened flip:(BOOL)flip;
{
    [NTIconCompositor drawIconForRef:iconRef inRect:rect label:label selected:selected opened:opened flip:flip alpha:1.0];
}

+ (void)drawIconForRef:(IconRef)iconRef inRect:(NSRect)rect label:(int)label selected:(BOOL)selected opened:(BOOL)opened flip:(BOOL)flip alpha:(float)alpha;
{
	[NTIconCompositor drawIconForRef:iconRef inRect:rect label:label selected:selected opened:opened flip:flip alpha:alpha alignment:kAlignAbsoluteCenter];
}

+ (void)drawIconForRef:(IconRef)iconRef
				inRect:(NSRect)inRect
				 label:(int)label 
			  selected:(BOOL)selected 
				opened:(BOOL)opened 
				  flip:(BOOL)flip 
				 alpha:(float)alpha 
			 alignment:(int)alignment;
{
    CGContextRef contextRef = [[NSGraphicsContext currentContext] graphicsPort];
    int transform = kTransformNone;
    NSColor *labelColor=nil;
    CGRect cgrect;
    NSRect rect = inRect;
    BOOL savedState=NO;
            
    if (alpha != 1.0)
    {
        if (!savedState)
        {
            [NSGraphicsContext saveGraphicsState];
            savedState = YES;
        }
        
        CGContextSetAlpha(contextRef, alpha);
    }

    if (label >= 1 && label <= 7)
    {
        switch (label)
        {
            case 1:
                transform |= kTransformLabel1;
                break;
            case 2:
                transform |= kTransformLabel2;
                break;
            case 3:
                transform |= kTransformLabel3;
                break;
            case 4:
                transform |= kTransformLabel4;
                break;
            case 5:
                transform |= kTransformLabel5;
                break;
            case 6:
                transform |= kTransformLabel6;
                break;
            case 7:
                transform |= kTransformLabel7;
                break;
        }

        labelColor = [[NTLabelColorMgr sharedInstance] color:label];
    }

    if (selected)
        transform |= kTransformSelected;
	
	// SNG doesn't work (10.5 tested)
	//  if (opened)
	//     transform |= kTransformOpen;
    
    if (flip)
    {
        if (!savedState)
        {
            [NSGraphicsContext saveGraphicsState];
            savedState = YES;
        }
        
        CGContextTranslateCTM(contextRef, 0, NSMaxY(rect));
        CGContextScaleCTM(contextRef, 1, -1);
		
        rect.origin.y = 0; // We've translated ourselves so it's zero
    }
    
    cgrect = *((CGRect*)&rect);
    
	PlotIconRefInContext(contextRef,
						 &cgrect,
						 alignment,
						 transform,
						 nil,
						 kPlotIconRefNormalFlags,
						 iconRef);
    
    // restore graphics port
    if (savedState)
        [NSGraphicsContext restoreGraphicsState];
    
    if (labelColor)
        [self drawLabelColor:labelColor inRect:inRect flip:flip];
}

+ (BOOL)iconRef:(IconRef)iconRef inRect:(NSRect)inIconRect intersectsRect:(NSRect)inTestRect flip:(BOOL)flip;
{
	// this call is not thread safe, make sure we don't accidentally use it
	if (![NSThread inMainThread])
        [NSException raise:NSInternalInconsistencyException format:@"RectInIconRef is not thread-safe"];
	
	// do the rects at least intersect?
	if (NSIntersectsRect(inIconRect, inTestRect))
	{
		// save time, if intersection is equal to iconRect, it must be YES
		if (NSEqualRects(inIconRect, NSIntersectionRect(inIconRect, inTestRect)))
			return YES;
		
		// slow
		if (IconRefIntersectsCGRect((CGRect*)&inTestRect, 
									(CGRect*)&inIconRect,
									kAlignAbsoluteCenter,
									kIconServicesNormalUsageFlag,
									iconRef))		
		{
			return YES;
		}
	}
	
	return NO;
}	

+ (BOOL)iconRef:(IconRef)iconRef inRect:(NSRect)inIconRect intersectsPoint:(NSPoint)inTestPoint flip:(BOOL)flip;
{
	// this call is not thread safe, make sure we don't accidentally use it
	if (![NSThread inMainThread])
        [NSException raise:NSInternalInconsistencyException format:@"PtInIconRef is not thread-safe"];
	
	if (IconRefContainsCGPoint((CGPoint*)&inTestPoint,
							   (CGRect*)&inIconRect,
							   kAlignAbsoluteCenter,
							   kIconServicesNormalUsageFlag,
							   iconRef))
	{
		return YES;
	}
	
	return NO;
}	

@end

@implementation NTIconCompositor (Private)

+ (void)drawLabelColor:(NSColor*)labelColor inRect:(NSRect)rect flip:(BOOL)flip;
{
    static int sPathSize = -1;
    static NSBezierPath* sLabelPath=nil;
    static NTGradientFill* sGradientFill=nil;
    
    if (rect.size.width != sPathSize)
    {
        NSRect labelRect;
                
        labelRect.size.height = rect.size.height / 3;
        labelRect.size.width = rect.size.width / 3;
        labelRect.origin = NSMakePoint(0, labelRect.size.height);

        sPathSize = rect.size.width;
        
        [sLabelPath release];
        sLabelPath = [[NSBezierPath roundRectPath:labelRect radius:MAX(labelRect.size.width/4, 2.0)] retain];
    }
    
    if (!sGradientFill)
        sGradientFill = [[NTGradientFill alloc] initWithType:kNTMediumGradient flip:YES];
    
    SGS;
    {
        CGContextRef contextRef = [[NSGraphicsContext currentContext] graphicsPort];
        
        if (flip)
        {
            CGContextTranslateCTM(contextRef, 0, NSMaxY(rect));
            CGContextScaleCTM(contextRef, 1, -1);
            
            rect.origin.y = 0; // We've translated ourselves so it's zero
        }
        
        CGAffineTransform transform = CGAffineTransformIdentity;
        transform = CGAffineTransformTranslate(transform, rect.origin.x, rect.origin.y);        
        CGContextConcatCTM(contextRef, transform);
        
        [sGradientFill fillBezierPath:sLabelPath withColor:[labelColor colorWithAlphaComponent:.8]];
    }
    RGS;
}

@end
