//
//  NTImageTypeMgr.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Tue Jul 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NTImageTypeMgr.h"

@interface NTImageTypeMgr (Private)
- (void)buildImageSets;
@end

@implementation NTImageTypeMgr

+ (void)initialize;
{
    NTINITIALIZE;

    [self sharedInstance]; // set up here so it's thread safe
}

+ (id)sharedInstance;
{
    static id shared=nil;
    
    if (!shared)
        shared = [[self alloc] init];
    
    return shared;
}

- (id)init;
{
    self = [super init];
    
    [self buildImageSets];

    return self;
}

- (BOOL)isImageHFSType:(OSType)type;
{
    return ([_imageHFSTypesSet member:[NSNumber numberWithUnsignedInt:type]] != nil);
}

- (BOOL)isImageExtension:(NSString*)extension;
{
    return ([_imageExtensionsSet member:[extension lowercaseString]] != nil);
}

@end

@implementation NTImageTypeMgr (Private)

- (void)buildImageSets;
{
    NSArray* types = [NSImage imageFileTypes];
    NSMutableSet* extensionsSet = [NSMutableSet setWithCapacity:[types count]];
    NSMutableSet* hfsTypesSet = [NSMutableSet setWithCapacity:[types count]];
    
    NSString* imageType;
    
    for (imageType in types)
    {
        if ([imageType length])
        {
            // is this a file type - ie: 'TEXT'
            if ([imageType characterAtIndex:0] == '\'' && [imageType characterAtIndex:([imageType length]-1)] == '\'')
            {
                // this function works with the apostrophes, so use it instead of stringToInt
                OSType hfsType = NSHFSTypeCodeFromFileType(imageType);
                
                [hfsTypesSet addObject:[NSNumber numberWithUnsignedInt:hfsType]];
            }
            else
                [extensionsSet addObject:[imageType lowercaseString]];
        }
    }
    
    // now convert the sets to immutable
    _imageHFSTypesSet = [[NSSet alloc] initWithSet:hfsTypesSet];
    _imageExtensionsSet = [[NSSet alloc] initWithSet:extensionsSet];
}

@end
