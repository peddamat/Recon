//
//  NTVolumeMgrState.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 3/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTVolumeMgrState : NSObject
{
    UInt64 buildNumber;
}

@property (assign) UInt64 buildNumber;

+ (NTVolumeMgrState*)state;
- (BOOL)changed;

+ (void)incrementBuild;

@end
