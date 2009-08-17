//
//  NTMetadata.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 6/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTMetadata : NSObject 
{
	NSString* mPath;
	
	MDItemRef mMdItemRef;
	
	NSArray* mv_attributeNames;
	NSArray* mv_valueStrings;
}

+ (NTMetadata*)metadata:(NSString*)path;

- (MDItemRef)mdItemRef;

- (NSArray *)attributeNames;
- (NSArray *)valueStrings;

// converts value in to a string suitable for display (remove \n, \r, \t)
- (NSString*)displayValue:(id)value forAttribute:(NSString*)attributeName;
- (NSString*)displayValueForAttribute:(NSString*)attributeName;

- (id)valueForAttribute:(NSString*)attribute;

@end

@interface NTMetadata (Utilities)
- (NSSize)imageSizeMD;
- (NSString*)imageSizeStringMD;
- (NSSize)imageDPIMD;
@end