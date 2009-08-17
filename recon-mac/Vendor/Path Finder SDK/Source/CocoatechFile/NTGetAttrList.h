//
//  NTGetAttrList.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Sun Dec 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NTGetAttrList : NSObject
{
}

+ (BOOL)volumeSupportsSearchFS:(const char*)UTFPath;

+ (void)test:(const char *)path;

@end
