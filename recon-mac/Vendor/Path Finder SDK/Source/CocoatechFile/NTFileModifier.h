//
//  NTFileModifier.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/10/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTFileModifier : NSObject {

}

+ (BOOL)setFileInfo:(FileInfo*)fileInfo desc:(NTFileDesc*)desc;

+ (BOOL)setPermissions:(unsigned long)permissions desc:(NTFileDesc*)desc;

+ (BOOL)setType:(OSType)type desc:(NTFileDesc*)desc;
+ (BOOL)setCreator:(OSType)creator desc:(NTFileDesc*)desc;
+ (BOOL)setExtensionHidden:(BOOL)set desc:(NTFileDesc*)desc;
+ (BOOL)setLock:(BOOL)set desc:(NTFileDesc*)desc;
+ (BOOL)setStationery:(BOOL)set desc:(NTFileDesc*)desc;
+ (BOOL)setHasBundle:(BOOL)set desc:(NTFileDesc*)desc;
+ (BOOL)setAlias:(BOOL)set desc:(NTFileDesc*)desc;
+ (BOOL)setLabel:(int)label desc:(NTFileDesc*)desc;
+ (BOOL)setFinderPosition:(NSPoint)point desc:(NTFileDesc*)desc;
+ (BOOL)setInvisible:(BOOL)set desc:(NTFileDesc*)desc;
+ (BOOL)setLength:(unsigned int)length desc:(NTFileDesc*)desc;

@end
