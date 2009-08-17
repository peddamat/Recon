//
//  NTFileAttributeModifier.h
//  CocoatechFile
//
//  Created by sgehrman on Wed Aug 08 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFileDesc;

@interface NTFileAttributeModifier : NSObject
{
}

+ (BOOL)touch:(NTFileDesc*)desc;
+ (BOOL)touchAttributeModificationDate:(NTFileDesc*)desc;

+ (BOOL)setModificationDate:(NSDate*)date desc:(NTFileDesc*)desc;
+ (BOOL)setCreationDate:(NSDate*)date desc:(NTFileDesc*)desc;
+ (BOOL)setAttributeModificationDate:(NSDate*)date desc:(NTFileDesc*)desc;

// application bindings
+ (BOOL)setApplicationBinding:(NTFileDesc*)application forFile:(NTFileDesc*)desc;
+ (BOOL)setApplicationBinding:(NTFileDesc*)application forFilesLike:(NTFileDesc*)desc;

@end
