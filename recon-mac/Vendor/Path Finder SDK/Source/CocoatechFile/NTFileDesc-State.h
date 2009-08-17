//
//  NTFileDesc-State.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFileDesc.h"

@interface NTFileDesc (State)

// a quick check to see if we have the information yet
// this is used for situations for speed where we want to draw what we have and not delay the main thread getting more stuff off the disk (or network)
- (BOOL)icon_intialized;
- (BOOL)displayName_initialized;
- (BOOL)kindString_initialized;
- (BOOL)hasDirectoryContents_initialized;

- (BOOL)size_initialized; // used for both files and folders
- (BOOL)physicalSize_initialized;

- (BOOL)modificationDate_initialized;
- (BOOL)creationDate_initialized;
- (BOOL)attributeDate_initialized;
- (BOOL)itemInfo_initialized;

@end
