//
//  GBUtilities.h
//  iLike
//
//  Created by Steve Gehrman on 9/28/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GBUtilities : NSObject {
}

+ (BOOL)extensionIsMusic:(NSString*)ext;
+ (NSView*)findView:(NSView*)view ofClass:(Class)class;

@end

@interface NSString (GBAdditions)
- (NSString*)GB_stringByReplacing:(NSString *)value with:(NSString *)newValue;
- (NSString *)GB_stringByRemovingPrefix:(NSString *)prefix;
- (NSString *)GB_stringByRemovingSuffix:(NSString *)suffix;
- (NSString*)GB_canonicalString;
- (NSString*)GB_stringByReplacingOccurrencesOfCharactersInSet:(NSCharacterSet *)set toString:(NSString *)replaceString;
@end
