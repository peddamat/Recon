//
//  NTIconCompositor.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Wed Aug 14 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFileDesc;

@interface NTIconCompositor : NSObject
{
}

+ (void)drawIconFor:(NTFileDesc*)desc inRect:(NSRect)rect drawLabel:(BOOL)drawLabel flip:(BOOL)flip;
+ (void)drawIconFor:(NTFileDesc*)desc inRect:(NSRect)rect selected:(BOOL)selected opened:(BOOL)opened drawLabel:(BOOL)drawLabel flip:(BOOL)flip;
+ (void)drawIconForRef:(IconRef)ref inRect:(NSRect)rect label:(int)label selected:(BOOL)selected opened:(BOOL)opened flip:(BOOL)flip;
+ (void)drawIconForRef:(IconRef)ref inRect:(NSRect)rect label:(int)label selected:(BOOL)selected opened:(BOOL)opened flip:(BOOL)flip alpha:(float)alpha;

+ (void)drawIconForRef:(IconRef)iconRef
				inRect:(NSRect)inRect
				 label:(int)label 
			  selected:(BOOL)selected 
				opened:(BOOL)opened 
				  flip:(BOOL)flip 
				 alpha:(float)alpha 
			 alignment:(int)alignment;

// hit testing, not thread safe!
+ (BOOL)iconRef:(IconRef)iconRef inRect:(NSRect)inIconRect intersectsRect:(NSRect)inTestRect flip:(BOOL)flip;
+ (BOOL)iconRef:(IconRef)iconRef inRect:(NSRect)inIconRect intersectsPoint:(NSPoint)inTestPoint flip:(BOOL)flip;

@end
