//
//  NTiLikeXMLUtilities.h
//  iLike
//
//  Created by Steve Gehrman on 4/20/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTiLikeXMLUtilities : NSObject {
}

+ (NSString*)convertKey:(NSString*)key;
+ (NSString*)cleanString:(NSString*)str;
+ (NSDictionary*)cleanInfoDict:(NSDictionary*)trackDict;

+ (NSDate*)dateFromString:(NSString*)dateString;

@end
