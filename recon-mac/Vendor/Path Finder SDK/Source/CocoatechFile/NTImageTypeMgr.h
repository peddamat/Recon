//
//  NTImageTypeMgr.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Tue Jul 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
// 

#import <Cocoa/Cocoa.h>

@interface NTImageTypeMgr : NSObject
{
    NSSet* _imageHFSTypesSet;
    NSSet* _imageExtensionsSet;
}

+ (id)sharedInstance;

- (BOOL)isImageHFSType:(OSType)type;
- (BOOL)isImageExtension:(NSString*)extension;

@end
