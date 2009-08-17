//
//  NTCGImage.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/21/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTCGImage : NSObject {

}

// array of dictionaries
+ (NSArray*)imageInformation:(NTFileDesc*)imageFile convertObjectsToStrings:(BOOL)convertObjectsToStrings;

// returns a width x height string
+ (NSString*)imageSizeString:(NTFileDesc*)imageFile;
+ (NSSize)imageSize:(NTFileDesc*)imageFile;

@end
