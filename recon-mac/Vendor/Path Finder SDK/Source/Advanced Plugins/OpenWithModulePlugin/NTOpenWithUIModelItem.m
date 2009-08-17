//
//  NTOpenWithUIModelItem.m
//  OpenWithModulePlugin
//
//  Created by Steve Gehrman on 3/3/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTOpenWithUIModelItem.h"

@implementation NTOpenWithUIModelItem

+ (NTOpenWithUIModelItem*)item:(NTFileDesc*)desc;
{
	NTOpenWithUIModelItem* result = [[NTOpenWithUIModelItem alloc] init];
	
	[result setDesc:desc];
	
	return [result autorelease];
}

+ (NTOpenWithUIModelItem*)separator;
{
	return [self item:nil];
}

+ (NTOpenWithUIModelItem*)itemWithCommand:(int)command title:(NSString*)title;
{
	NTOpenWithUIModelItem* result = [self item:nil];
	
	[result setCommand:command];
	[result setTitle:title];
	
	return result;  // already autoreleased
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setDesc:nil];
    [self setTitle:nil];
    [self setImage:nil];
    [super dealloc];
}

- (NSComparisonResult)compareByName:(NTOpenWithUIModelItem *)fsi
{
    return ([[self desc] compareByDisplayName:[fsi desc]]);
}

//---------------------------------------------------------- 
//  desc 
//---------------------------------------------------------- 
- (NTFileDesc *)desc
{
    return mDesc; 
}

- (void)setDesc:(NTFileDesc *)theDesc
{
    if (mDesc != theDesc)
    {
        [mDesc release];
        mDesc = [theDesc retain];
    }
}

// for sorting and locating the selected object
- (BOOL)isEqual:(NTOpenWithUIModelItem *)right;
{
	return [[self description] isEqualToString:[right description]];
}

- (NSComparisonResult)compare:(NTOpenWithUIModelItem *)right;
{
	return [[self description] compare:[right description]];
}

- (NSString*)description;
{
	if ([self title])
		return [self title];
	
	// this funky string is converted in the applications NSMenuItemHack class 
	if ([self desc])
		return [NSString stringWithFormat:@"::$$%@$$%d", [[self desc] path], kSmallMenuIconSize];
	
	// separator item
	return [NSString stringWithFormat:@"::$$%@$$%d", @"-", kSmallMenuIconSize];
}

//---------------------------------------------------------- 
//  command 
//---------------------------------------------------------- 
- (int)command
{
    return mCommand;
}

- (void)setCommand:(int)theCommand
{
    mCommand = theCommand;
}

//---------------------------------------------------------- 
//  title 
//---------------------------------------------------------- 
- (NSString *)title
{	
    return mTitle; 
}

- (void)setTitle:(NSString *)theTitle
{
    if (mTitle != theTitle)
    {
        [mTitle release];
        mTitle = [theTitle retain];
    }
}

//---------------------------------------------------------- 
//  image 
//---------------------------------------------------------- 
- (NSImage *)image
{
	if (!mImage)
		[self setImage:nil];
	
    return mImage; 
}

- (void)setImage:(NSImage *)theImage
{
    if (mImage != theImage)
    {
        [mImage release];
        mImage = [theImage retain];
    }
}

@end
