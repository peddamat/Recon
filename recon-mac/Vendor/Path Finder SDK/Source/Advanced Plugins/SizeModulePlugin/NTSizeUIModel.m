//
//  NTSizeUIModel.m
//  SizeModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTSizeUIModel.h"

@implementation NTSizeUIModel

+ (NTSizeUIModel*)model;
{
	NTSizeUIModel* result = [[NTSizeUIModel alloc] init];
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setName:nil];
    [self setInfo:nil];
    [self setSize:nil];
    [self setIcon:nil];
	[self setSizeToolTip:nil];

    [super dealloc];
}

//---------------------------------------------------------- 
//  name 
//---------------------------------------------------------- 
- (NSString *)name
{
    return mName; 
}

- (void)setName:(NSString *)theName
{
    if (mName != theName)
    {
        [mName release];
        mName = [theName retain];
    }
}

//---------------------------------------------------------- 
//  info 
//---------------------------------------------------------- 
- (NSString *)info
{
    return mInfo; 
}

- (void)setInfo:(NSString *)theInfo
{
    if (mInfo != theInfo)
    {
        [mInfo release];
        mInfo = [theInfo retain];
    }
}

//---------------------------------------------------------- 
//  size 
//---------------------------------------------------------- 
- (NSString *)size
{
    return mSize; 
}

- (void)setSize:(NSString *)theSize
{
    if (mSize != theSize)
    {
        [mSize release];
        mSize = [theSize retain];
    }
}

//---------------------------------------------------------- 
//  icon 
//---------------------------------------------------------- 
- (NSImage *)icon
{
    return mIcon; 
}

- (void)setIcon:(NSImage *)theIcon
{
    if (mIcon != theIcon)
    {
        [mIcon release];
        mIcon = [theIcon retain];
    }
}

//---------------------------------------------------------- 
//  sizeToolTip 
//---------------------------------------------------------- 
- (NSString *)sizeToolTip
{
    return mSizeToolTip; 
}

- (void)setSizeToolTip:(NSString *)theSizeToolTip
{
    if (mSizeToolTip != theSizeToolTip)
    {
        [mSizeToolTip release];
        mSizeToolTip = [theSizeToolTip retain];
    }
}

@end

