//
//  NTCarbonFileInfo.m
//  CocoatechFile
//
//  Created by sgehrman on Mon Jul 16 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NTCarbonFileInfo.h"

@implementation NTCarbonFileInfo

- (id)initWithDesc:(NTFileDesc*)desc
{
    OSStatus err;
    FSCatalogInfo catalogInfo;

    self = [super init];

    _valid = NO;
    _desc = [desc retain];

    // Get the FinderInfo for the file
    if ([_desc FSRefPtr])
    {
        err = FSGetCatalogInfo([_desc FSRefPtr], kFSCatInfoFinderInfo, &catalogInfo, NULL, NULL, NULL);
        if (err == noErr)
        {
            _fileInfo = *((FileInfo*)catalogInfo.finderInfo);

            _valid = YES;
        }
    }

    return self;
}

- (void)dealloc
{
    [_desc release];
    [super dealloc];
}

- (FileInfo*)fileInfo
{
    if (_valid)
        return &_fileInfo;

    return nil;
}

- (void)setFileInfo:(FileInfo*)fileInfo;
{
    if (_valid && [_desc FSRefPtr])
    {
        // Get the FinderInfo for the file
        FSCatalogInfo catalogInfo;
        OSErr err;

        *((FileInfo*)&catalogInfo.finderInfo) = *fileInfo;

        err = FSSetCatalogInfo([_desc FSRefPtr], kFSCatInfoFinderInfo, &catalogInfo);
        if (err == noErr)
            _fileInfo = *fileInfo;
    }
}

@end
