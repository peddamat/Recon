//
//  NTLabelColor.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 6/21/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTLabelColor.h"

@implementation NTLabelColor

+ (NTLabelColor*)label:(NSString*)name color:(NSColor*)color;
{
	NTLabelColor* result = [[NTLabelColor alloc] init];
	
	[result setName:[NTLocalizedString localize:name table:@"menuBar"]];
	[result setColor:color];
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setName:nil];
    [self setColor:nil];
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder 
{
    [coder encodeObject:[self name] forKey:@"Name"];
    [coder encodeObject:[self color] forKey:@"Color"];
}

- (id)initWithCoder:(NSCoder *)coder 
{
    self = [super init];
	
	if ([coder containsValueForKey:@"Name"])
		[self setName:[coder decodeObjectForKey:@"Name"]];
	if ([coder containsValueForKey:@"Color"])
		[self setColor:[coder decodeObjectForKey:@"Color"]];
	
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    id theCopy = nil;
	
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
	
    if (data)
        theCopy = [[NSKeyedUnarchiver unarchiveObjectWithData:data] retain];
	
    return theCopy;
}

- (NSArray *)keyPaths
{
    NSArray *result = [NSArray arrayWithObjects:
        @"name",
        @"color",
        nil];
	
    return result;
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
    if (mName != theName) {
        [mName release];
        mName = [theName retain];
    }
}

//---------------------------------------------------------- 
//  color 
//---------------------------------------------------------- 
- (NSColor *)color
{
    return mColor; 
}

- (void)setColor:(NSColor *)theColor
{
    if (mColor != theColor) {
        [mColor release];
        mColor = [theColor retain];
    }
}

@end

