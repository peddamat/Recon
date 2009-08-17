//
//  NTFileDesc-DirectoryContents.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFileDesc.h"

@interface NTFileDesc (DirectoryContents)

- (NSArray*)directoryContents:(BOOL)visibleOnly resolveIfAlias:(BOOL)resolveIfAlias;

// *** caller must release, not autoreleased
- (NSArray*)directoryContents:(BOOL)visibleOnly resolveIfAlias:(BOOL)resolveIfAlias infoBitmap:(FSCatalogInfoBitmap)infoBitmap;

- (BOOL)hasDirectoryContents:(BOOL)visibleOnly;

// used for delete, we must filter out ._ files that have a matching data file
// visibleOnly=NO, resolveIfAlias=NO
- (NSArray*)directoryContentsForDelete;

@end
