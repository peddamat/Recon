//
//  NTResourceInfo.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTResourceInfo.h"

@implementation NTResourceInfo

- (id)initForType:(OSType)type resID:(int)resID name:(NSString*)name offset:(int)offset size:(int)size;
{
    self = [super init];
	
    _name = [name retain];
    _type = type;
    _resID = resID;
	
    _offset = offset;
    _size = size;
	
    return self;
}

- (void)dealloc;
{
    [_name release];
    [super dealloc];
}

+ (NTResourceInfo*)resourceInfoForType:(OSType)type resID:(int)resID name:(NSString*)name offset:(int)offset size:(int)size;
{
    NTResourceInfo* result = [[NTResourceInfo alloc] initForType:type resID:resID name:name offset:offset size:size];
	
    return [result autorelease];
}

- (NSString*)name;
{
    return _name;
}

- (OSType)type;
{
    return _type;
}

- (int)resID;
{
    return _resID;
}

- (int)size;
{
    return _size;
}

- (int)offset;
{
    return _offset;
}

@end

