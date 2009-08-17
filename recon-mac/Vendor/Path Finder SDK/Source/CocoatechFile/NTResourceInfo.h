//
//  NTResourceInfo.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTResourceInfo : NSObject
{
    NSString* _name;
    OSType _type;
    int _resID;
    int _offset;
    int _size;
}

+ (NTResourceInfo*)resourceInfoForType:(OSType)type resID:(int)resID name:(NSString*)name offset:(int)offset size:(int)size;

- (NSString*)name;
- (OSType)type;
- (int)resID;
- (int)size;
- (int)offset;

@end
