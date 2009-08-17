//
//  NTCarbonFileInfo.h
//  CocoatechFile
//
//  Created by sgehrman on Mon Jul 16 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

@class NTFileDesc;

@interface NTCarbonFileInfo : NSObject
{
    BOOL _valid;
    NTFileDesc* _desc;
    FileInfo _fileInfo;
}

- (id)initWithDesc:(NTFileDesc*)desc;
- (FileInfo*)fileInfo;
- (void)setFileInfo:(FileInfo*)fileInfo;

@end
