//
//  NTLaunchServices.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Wed Mar 17 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NTLaunchServices : NSObject
{
}

+ (BOOL)launchDescs:(NSArray*)descs withApp:(NSString*)appPath;  // kLSLaunchDefaults launch flags
+ (BOOL)launchDescs:(NSArray*)descs withApp:(NSString*)appPath launchFlags:(LSLaunchFlags)launchFlags;

+ (BOOL)printDescs:(NSArray*)descs;

	// get a list of apps that can open a document
+ (NSArray*)LSCopyApplicationURLsForItem:(NTFileDesc*)inDesc;

// get all applications
+ (NSArray*)applications;

@end
