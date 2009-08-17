//
//  NTStringShare.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Sat Dec 06 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NTStringShare : NSObject
{    
	NSLock *mKindLock;
	NSLock *mExtensionLock;
	
    NSMutableSet* mKindStrings;
    NSMutableSet* mExtensionStrings;
}

+ (NTStringShare*)sharedInstance;

- (NSString*)sharedKindString:(NSString*)kindString;
- (NSString*)sharedExtensionString:(NSString*)extensionString;

@end

// ============================================================================================
// standard kind strings

@interface NTStringShare (StandardKindStrings)

+ (NSString*)packageKindString;
+ (NSString*)volumeKindString;
+ (NSString*)folderKindString;
+ (NSString*)symbolicLinkKindString;
+ (NSString*)documentKindString;

@end
