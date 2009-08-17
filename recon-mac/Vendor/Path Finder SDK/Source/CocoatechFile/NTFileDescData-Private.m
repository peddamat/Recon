//
//  NTFileDescData-Private.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/25/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFileDescData-Private.h"

@implementation NTFileDescData (Private)

//---------------------------------------------------------- 
//  cachedIsFile 
//---------------------------------------------------------- 
- (BOOL)cachedIsFile
{
    return mv_bools.mv_cachedIsFile;
}

- (void)setCachedIsFile:(BOOL)flag
{
    mv_bools.mv_cachedIsFile = flag;
}

//---------------------------------------------------------- 
//  cachedIsApplication 
//---------------------------------------------------------- 
- (BOOL)cachedIsApplication
{
    return mv_bools.mv_cachedIsApplication;
}

- (void)setCachedIsApplication:(BOOL)flag
{
    mv_bools.mv_cachedIsApplication = flag;
}

//---------------------------------------------------------- 
//  cachedIsPackage 
//---------------------------------------------------------- 
- (BOOL)cachedIsPackage
{
    return mv_bools.mv_cachedIsPackage;
}

- (void)setCachedIsPackage:(BOOL)flag
{
    mv_bools.mv_cachedIsPackage = flag;
}

//---------------------------------------------------------- 
//  cachedIsCarbonAlias 
//---------------------------------------------------------- 
- (BOOL)cachedIsCarbonAlias
{
    return mv_bools.mv_cachedIsCarbonAlias;
}

- (void)setCachedIsCarbonAlias:(BOOL)flag
{
    mv_bools.mv_cachedIsCarbonAlias = flag;
}

//---------------------------------------------------------- 
//  cachedIsPathFinderAlias 
//---------------------------------------------------------- 
- (BOOL)cachedIsPathFinderAlias
{
    return mv_bools.mv_cachedIsPathFinderAlias;
}

- (void)setCachedIsPathFinderAlias:(BOOL)flag
{
    mv_bools.mv_cachedIsPathFinderAlias = flag;
}

//---------------------------------------------------------- 
//  cachedIsSymbolicLink 
//---------------------------------------------------------- 
- (BOOL)cachedIsSymbolicLink
{
    return mv_bools.mv_cachedIsSymbolicLink;
}

- (void)setCachedIsSymbolicLink:(BOOL)flag
{
    mv_bools.mv_cachedIsSymbolicLink = flag;
}

//---------------------------------------------------------- 
//  cachedIsInvisible 
//---------------------------------------------------------- 
- (BOOL)cachedIsInvisible
{
    return mv_bools.mv_cachedIsInvisible;
}

- (void)setCachedIsInvisible:(BOOL)flag
{
    mv_bools.mv_cachedIsInvisible = flag;
}

//---------------------------------------------------------- 
//  cachedIsExtensionHidden 
//---------------------------------------------------------- 
- (BOOL)cachedIsExtensionHidden
{
    return mv_bools.mv_cachedIsExtensionHidden;
}

- (void)setCachedIsExtensionHidden:(BOOL)flag
{
    mv_bools.mv_cachedIsExtensionHidden = flag;
}

//---------------------------------------------------------- 
//  cachedIsLocked 
//---------------------------------------------------------- 
- (BOOL)cachedIsLocked
{
    return mv_bools.mv_cachedIsLocked;
}

- (void)setCachedIsLocked:(BOOL)flag
{
    mv_bools.mv_cachedIsLocked = flag;
}

//---------------------------------------------------------- 
//  cachedHasCustomIcon 
//---------------------------------------------------------- 
- (BOOL)cachedHasCustomIcon
{
    return mv_bools.mv_cachedHasCustomIcon;
}

- (void)setCachedHasCustomIcon:(BOOL)flag
{
    mv_bools.mv_cachedHasCustomIcon = flag;
}

//---------------------------------------------------------- 
//  cachedIsStationery 
//---------------------------------------------------------- 
- (BOOL)cachedIsStationery
{
    return mv_bools.mv_cachedIsStationery;
}

- (void)setCachedIsStationery:(BOOL)flag
{
    mv_bools.mv_cachedIsStationery = flag;
}

//---------------------------------------------------------- 
//  cachedIsBundleBitSet 
//---------------------------------------------------------- 
- (BOOL)cachedIsBundleBitSet
{
    return mv_bools.mv_cachedIsBundleBitSet;
}

- (void)setCachedIsBundleBitSet:(BOOL)flag
{
	mv_bools.mv_cachedIsBundleBitSet = flag;
}

//---------------------------------------------------------- 
//  cachedIsAliasBitSet 
//---------------------------------------------------------- 
- (BOOL)cachedIsAliasBitSet
{
    return mv_bools.mv_cachedIsAliasBitSet;
}

- (void)setCachedIsAliasBitSet:(BOOL)flag
{
    mv_bools.mv_cachedIsAliasBitSet = flag;
}

//---------------------------------------------------------- 
//  cachedIsReadable 
//---------------------------------------------------------- 
- (BOOL)cachedIsReadable
{
    return mv_bools.mv_cachedIsReadable;
}

- (void)setCachedIsReadable:(BOOL)flag
{
    mv_bools.mv_cachedIsReadable = flag;
}

//---------------------------------------------------------- 
//  cachedIsExecutable
//---------------------------------------------------------- 
- (BOOL)cachedIsExecutable
{
    return mv_bools.mv_cachedIsExecutable;
}

- (void)setCachedIsExecutable:(BOOL)flag
{
    mv_bools.mv_cachedIsExecutable = flag;
}

//---------------------------------------------------------- 
//  cachedIsWritable 
//---------------------------------------------------------- 
- (BOOL)cachedIsWritable
{
    return mv_bools.mv_cachedIsWritable;
}

- (void)setCachedIsWritable:(BOOL)flag
{
    mv_bools.mv_cachedIsWritable = flag;
}

//---------------------------------------------------------- 
//  cachedIsDeletable 
//---------------------------------------------------------- 
- (BOOL)cachedIsDeletable
{
    return mv_bools.mv_cachedIsDeletable;
}

- (void)setCachedIsDeletable:(BOOL)flag
{
    mv_bools.mv_cachedIsDeletable = flag;
}

//---------------------------------------------------------- 
//  cachedIsRenamable 
//---------------------------------------------------------- 
- (BOOL)cachedIsRenamable
{
    return mv_bools.mv_cachedIsRenamable;
}

- (void)setCachedIsRenamable:(BOOL)flag
{
    mv_bools.mv_cachedIsRenamable = flag;
}

//---------------------------------------------------------- 
//  cachedIsReadOnly
//---------------------------------------------------------- 
- (BOOL)cachedIsReadOnly
{
    return mv_bools.mv_cachedIsReadOnly;
}

- (void)setCachedIsReadOnly:(BOOL)flag
{
    mv_bools.mv_cachedIsReadOnly = flag;
}

//---------------------------------------------------------- 
//  cachedIsMovable 
//---------------------------------------------------------- 
- (BOOL)cachedIsMovable
{
    return mv_bools.mv_cachedIsMovable;
}

- (void)setCachedIsMovable:(BOOL)flag
{
    mv_bools.mv_cachedIsMovable = flag;
}

//---------------------------------------------------------- 
//  cachedIsStickyBitSet 
//---------------------------------------------------------- 
- (BOOL)cachedIsStickyBitSet
{
    return mv_bools.mv_cachedIsStickyBitSet;
}

- (void)setCachedIsStickyBitSet:(BOOL)flag
{
    mv_bools.mv_cachedIsStickyBitSet = flag;
}

//---------------------------------------------------------- 
//  cachedIsPipe 
//---------------------------------------------------------- 
- (BOOL)cachedIsPipe
{
    return mv_bools.mv_cachedIsPipe;
}

- (void)setCachedIsPipe:(BOOL)flag
{
    mv_bools.mv_cachedIsPipe = flag;
}

//---------------------------------------------------------- 
//  cachedIsVolume 
//---------------------------------------------------------- 
- (BOOL)cachedIsVolume
{
    return mv_bools.mv_cachedIsVolume;
}

- (void)setCachedIsVolume:(BOOL)flag
{
    mv_bools.mv_cachedIsVolume = flag;
}

//---------------------------------------------------------- 
//  cachedHasDirectoryContents 
//---------------------------------------------------------- 
- (BOOL)cachedHasDirectoryContents
{
    return mv_bools.mv_cachedHasDirectoryContents;
}

- (void)setCachedHasDirectoryContents:(BOOL)flag
{
	mv_bools.mv_cachedHasDirectoryContents = flag;
}

//---------------------------------------------------------- 
//  cachedHasVisibleDirectoryContents 
//---------------------------------------------------------- 
- (BOOL)cachedHasVisibleDirectoryContents
{
    return mv_bools.mv_cachedHasVisibleDirectoryContents;
}

- (void)setCachedHasVisibleDirectoryContents:(BOOL)flag
{
    mv_bools.mv_cachedHasVisibleDirectoryContents = flag;
}

//---------------------------------------------------------- 
//  cachedIsServerAlias 
//---------------------------------------------------------- 
- (BOOL)cachedIsServerAlias
{
    return mv_bools.mv_cachedIsServerAlias;
}

- (void)setCachedIsServerAlias:(BOOL)flag
{
    mv_bools.mv_cachedIsServerAlias = flag;
}

//---------------------------------------------------------- 
//  cachedIsBrokenAlias 
//---------------------------------------------------------- 
- (BOOL)cachedIsBrokenAlias
{
    return mv_bools.mv_cachedIsBrokenAlias;
}

- (void)setCachedIsBrokenAlias:(BOOL)flag
{
    mv_bools.mv_cachedIsBrokenAlias = flag;
}

//---------------------------------------------------------- 
//  cachedIsParentAVolume 
//---------------------------------------------------------- 
- (BOOL)cachedIsParentAVolume
{
    return mv_bools.mv_cachedIsParentAVolume;
}

- (void)setCachedIsParentAVolume:(BOOL)flag
{
    mv_bools.mv_cachedIsParentAVolume = flag;
}

//---------------------------------------------------------- 
//  cachedIsNameLocked 
//---------------------------------------------------------- 
- (BOOL)cachedIsNameLocked
{
    return mv_bools.mv_cachedIsNameLocked;
}

- (void)setCachedIsNameLocked:(BOOL)flag
{
    mv_bools.mv_cachedIsNameLocked = flag;
}

//---------------------------------------------------------- 
//  cachedHasBeenModified 
//---------------------------------------------------------- 
- (BOOL)cachedHasBeenModified
{
    return mv_bools.mv_cachedHasBeenModified;
}

- (void)setCachedHasBeenModified:(BOOL)flag
{
	mv_bools.mv_cachedHasBeenModified = flag;
}

//---------------------------------------------------------- 
//  cachedHasBeenRenamed 
//---------------------------------------------------------- 
- (BOOL)cachedHasBeenRenamed
{
    return mv_bools.mv_cachedHasBeenRenamed;
}

- (void)setCachedHasBeenRenamed:(BOOL)flag
{
	mv_bools.mv_cachedHasBeenRenamed = flag;
}

@end
