//
//  NTIcon.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Wed Aug 14 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import "NTIcon.h"
#import "NSImage-CocoatechFile.h"

@implementation NTIcon

- (id)initWithRef:(IconRef)ref;
{
    self = [super init];

    if (ref)
    {
        OSErr err = AcquireIconRef(ref);

        if (err == noErr)
            _iconRef = ref;
    }

    return self;
}

// we are responsible for releasing
+ (id)iconWithRef:(IconRef)ref;
{
    NTIcon* result = [[NTIcon alloc] initWithRef:ref];

    return [result autorelease];
}

- (void)dealloc;
{
    if (_iconRef)
        ReleaseIconRef(_iconRef);

    [super dealloc];
}

- (NSUInteger)maxSizeAvailable;
{
	NSUInteger result = 512;
	if (!IsDataAvailableInIconRef(kIconServices512PixelDataARGB, [self iconRef]))
	{
		result = 256;
		if (!IsDataAvailableInIconRef(kIconServices256PixelDataARGB, [self iconRef]))
			result = 128;
	}
	
	return result;
}

- (IconRef)iconRef;
{
    return _iconRef;
}

- (NSImage*)imageForSize:(int)size;
{
	return [self imageForSize:size label:0 select:NO alpha:1.0];
}

- (NSImage*)imageForSize:(int)size label:(int)label select:(BOOL)select;
{
    return [self imageForSize:size label:label select:select alpha:1.0];
}

- (NSImage*)imageForSize:(int)size label:(int)label select:(BOOL)select alpha:(float)alpha;
{
    return [self imageForSize:size label:label select:select alpha:alpha alignment:kAlignAbsoluteCenter];
}

- (NSImage*)imageForSize:(int)size
				   label:(int)label
				  select:(BOOL)select 
				   alpha:(float)alpha 
			   alignment:(int)alignment;
{
	return [NSImage iconRef:_iconRef toImage:size label:label select:select alpha:alpha alignment:alignment];
}

@end
