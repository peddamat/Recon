//
//  NTVolumeMounter.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Tue Sep 03 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NTFileDesc;

@interface NTVolumeMounter : NSObject
{
    FSVolumeOperation _volumeOp;
    
    FSVolumeMountUPP _mountUPP;
    NSURL* url; // used for mount
    NSString* notificationName;
}

@property (retain) NSURL* url;
@property (retain) NSString* notificationName;

+ (void)mountVolumeWithScheme:(NSString*)scheme host:(NSString*)host path:(NSString*)path user:(NSString*)user password:(NSString*)password notifyWhenMounts:(NSString*)notificationName;
+ (void)mountVolumeWithURL:(NSURL*)url user:(NSString*)user password:(NSString*)password notifyWhenMounts:(NSString*)notificationName;

@end
