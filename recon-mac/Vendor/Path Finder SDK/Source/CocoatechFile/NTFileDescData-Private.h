//
//  NTFileDescData-Private.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/25/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFileDescData.h"

@interface NTFileDescData (Private);

- (BOOL)cachedIsFile;
- (void)setCachedIsFile:(BOOL)flag;

- (BOOL)cachedIsApplication;
- (void)setCachedIsApplication:(BOOL)flag;

- (BOOL)cachedIsPackage;
- (void)setCachedIsPackage:(BOOL)flag;

- (BOOL)cachedIsCarbonAlias;
- (void)setCachedIsCarbonAlias:(BOOL)flag;

- (BOOL)cachedIsPathFinderAlias;
- (void)setCachedIsPathFinderAlias:(BOOL)flag;

- (BOOL)cachedIsSymbolicLink;
- (void)setCachedIsSymbolicLink:(BOOL)flag;

- (BOOL)cachedIsInvisible;
- (void)setCachedIsInvisible:(BOOL)flag;

- (BOOL)cachedIsExtensionHidden;
- (void)setCachedIsExtensionHidden:(BOOL)flag;

- (BOOL)cachedIsLocked;
- (void)setCachedIsLocked:(BOOL)flag;

- (BOOL)cachedHasCustomIcon;
- (void)setCachedHasCustomIcon:(BOOL)flag;

- (BOOL)cachedIsStationery;
- (void)setCachedIsStationery:(BOOL)flag;

- (BOOL)cachedIsBundleBitSet;
- (void)setCachedIsBundleBitSet:(BOOL)flag;

- (BOOL)cachedIsAliasBitSet;
- (void)setCachedIsAliasBitSet:(BOOL)flag;

- (BOOL)cachedIsReadable;
- (void)setCachedIsReadable:(BOOL)flag;

- (BOOL)cachedIsExecutable;
- (void)setCachedIsExecutable:(BOOL)flag;

- (BOOL)cachedIsWritable;
- (void)setCachedIsWritable:(BOOL)flag;

- (BOOL)cachedIsDeletable;
- (void)setCachedIsDeletable:(BOOL)flag;

- (BOOL)cachedIsRenamable;
- (void)setCachedIsRenamable:(BOOL)flag;

- (BOOL)cachedIsReadOnly;
- (void)setCachedIsReadOnly:(BOOL)flag;

- (BOOL)cachedIsMovable;
- (void)setCachedIsMovable:(BOOL)flag;

- (BOOL)cachedIsStickyBitSet;
- (void)setCachedIsStickyBitSet:(BOOL)flag;

- (BOOL)cachedIsPipe;
- (void)setCachedIsPipe:(BOOL)flag;

- (BOOL)cachedIsVolume;
- (void)setCachedIsVolume:(BOOL)flag;

- (BOOL)cachedHasDirectoryContents;
- (void)setCachedHasDirectoryContents:(BOOL)flag;

- (BOOL)cachedHasVisibleDirectoryContents;
- (void)setCachedHasVisibleDirectoryContents:(BOOL)flag;

- (BOOL)cachedIsServerAlias;
- (void)setCachedIsServerAlias:(BOOL)flag;

- (BOOL)cachedIsBrokenAlias;
- (void)setCachedIsBrokenAlias:(BOOL)flag;

- (BOOL)cachedIsParentAVolume;
- (void)setCachedIsParentAVolume:(BOOL)flag;

- (BOOL)cachedIsNameLocked;
- (void)setCachedIsNameLocked:(BOOL)flag;

- (BOOL)cachedHasBeenModified;
- (void)setCachedHasBeenModified:(BOOL)flag;

- (BOOL)cachedHasBeenRenamed;
- (void)setCachedHasBeenRenamed:(BOOL)flag;

@end
