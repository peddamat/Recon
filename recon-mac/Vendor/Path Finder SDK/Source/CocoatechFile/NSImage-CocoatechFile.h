//
//  NSImage-CocoatechFile.h
//  CocoatechFile
//
//  Created by sgehrman on Fri Oct 12 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@class NTFileDesc, NTIcon;

@interface NSImage (CocoatechFile)

+ (NSImage *)imageForDesc:(NTFileDesc*)desc size:(int)size;
+ (NSImage *)imageForType:(OSType)iconType creator:(OSType)creator size:(int)size;
+ (NSImage *)imageForSystemType:(OSType)iconType size:(int)size; // passes kSystemIconsCreator for creator

+ (NSImage*)iconRef:(IconRef)iconRef toImage:(int)size;
+ (NSImage*)iconRef:(IconRef)iconRef toImage:(int)size select:(BOOL)select;
+ (NSImage*)iconRef:(IconRef)iconRef toImage:(int)size label:(int)label select:(BOOL)select;
+ (NSImage*)iconRef:(IconRef)iconRef toImage:(int)size label:(int)label select:(BOOL)select alpha:(float)alpha;
+ (NSImage*)iconRef:(IconRef)iconRef toImage:(int)size label:(int)label highlight:(BOOL)highlight; // used when clicking on an image button
+ (NSImage*)iconRef:(IconRef)iconRef
			toImage:(int)size 
			  label:(int)label 
			 select:(BOOL)select
			  alpha:(float)alpha
		  alignment:(int)alignment;

// these routines add a 32 and 24 size image so it will look good in the toolbar
+ (NSImage*)iconRefToToolbarImage:(IconRef)iconRef;
+ (NSImage*)imageToToolbarImage:(NSImage*)image;
+ (NSImage*)iconRefForToolbar:(IconRef)iconRef label:(int)label select:(BOOL)select;

// add a badge to an image, badge added to all imageReps
- (NSImage*)imageWithBadge:(NTIcon*)icon;
- (NSImage*)imageWithBadge:(NTIcon*)icon badgeSize:(int)badgeSize badgeOffset:(NSPoint)offset fraction:(float)fraction;

// call from thread, could be slow
// if a movie, get the poster image, if an audio file try to get the cover art, if anything else, just returns the icon
+ (NSImage*)imageFromNonImageFile:(NTFileDesc*)desc maxSize:(NSSize)maxSize asIcon:(BOOL)asIcon;
+ (NSImage *)quickLookPreviewImage:(NTFileDesc*)desc
							ofSize:(NSSize)size
							asIcon:(BOOL)icon;
@end
