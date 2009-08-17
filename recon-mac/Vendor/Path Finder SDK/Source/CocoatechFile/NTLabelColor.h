//
//  NTLabelColor.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 6/21/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTLabelColor : NSObject <NSCoding, NSCopying>
{
    NSString* mName;
    NSColor* mColor;
}

+ (NTLabelColor*)label:(NSString*)name color:(NSColor*)color;

- (NSArray *)keyPaths;

- (NSString *)name;
- (void)setName:(NSString *)theName;

- (NSColor *)color;
- (void)setColor:(NSColor *)theColor;

@end
