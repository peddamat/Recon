//
//  NTIcon.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Wed Aug 14 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

// this encapsulates an IconRef
@interface NTIcon : NSObject
{
    IconRef _iconRef;
}

+ (id)iconWithRef:(IconRef)iconRef;

- (IconRef)iconRef;
- (NSUInteger)maxSizeAvailable;

- (NSImage*)imageForSize:(int)size;

- (NSImage*)imageForSize:(int)size
				   label:(int)label 
				  select:(BOOL)select;

- (NSImage*)imageForSize:(int)size 
				   label:(int)label 
				  select:(BOOL)select
				   alpha:(float)alpha;

- (NSImage*)imageForSize:(int)size
				   label:(int)label
				  select:(BOOL)select 
				   alpha:(float)alpha 
			   alignment:(int)alignment;

@end
