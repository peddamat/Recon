/*
 *  NTFSItemProtocol.h
 *
 *  Created by Steve Gehrman on 5/5/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

@protocol NTFSItem <NSObject>

- (id<NTFSItem>)descResolveIfAlias;

- (BOOL)isValid;
- (BOOL)stillExists;
- (BOOL)isComputer;

- (NSPoint)finderPosition;
- (NSString*)versionString;
- (NSString*)bundleVersionString;
- (NSString*)infoString;
- (NSString*)itemInfo;
- (NSString*)uniformTypeID;

- (NSString *)path;
- (NSString*)displayPath; // path, or Computer for @"", or boot volumes name for "/"

- (NSURL*)URL;
- (const char *)fileSystemPath;
- (const char *)UTF8Path;

- (FSRef*)FSRefPtr;

- (UInt32)nodeID;
- (NSString *)name;
- (NSString*)displayName;
- (NSString *)extension;
- (NSString*)executablePath;
- (NSString*)dictionaryKey;
- (NSString*)bundleSignature;

- (id<NTFSItem>)parentDesc;
- (UInt32)parentDirID;
- (BOOL)parentIsVolume;
- (NSString *)parentPath:(BOOL)forDisplay;

- (FSVolumeRefNum)volumeRefNum;

- (NSString *)kindString;
- (NSString *)architecture;

- (UInt64)size; // returns total size for files or folders
- (UInt64)physicalSize; // returns total physical size for files or folders

- (int)numberOfForks;
- (UInt64)rsrcForkSize;
- (UInt64)dataForkSize;
- (UInt64)rsrcForkPhysicalSize;
- (UInt64)dataForkPhysicalSize;

- (UInt64)totalValence;  // only valid for folders, -1 if invalid
- (UInt32)valence;  // only valid for folders

- (BOOL)isOnBootVolume;

- (BOOL)isFile;
- (BOOL)isDirectory;
- (BOOL)isInvisible;
- (BOOL)isLocked;
- (BOOL)hasCustomIcon;
- (BOOL)isStationery;
- (BOOL)isBundleBitSet;
- (BOOL)isAliasBitSet;
- (BOOL)isPackage;
- (BOOL)isApplication;
- (BOOL)isExtensionHidden;
- (BOOL)isReadable;
- (BOOL)isWritable;
- (BOOL)isExecutable;
- (BOOL)isDeletable;
- (BOOL)isRenamable;

	// read only even if we had admin privleges
- (BOOL)isReadOnly;

- (BOOL)isMovable;
- (BOOL)isAlias; // returns YES if isCarbonAlias or isPathFinderAlias or isUnixSymbolicLink
- (BOOL)isCarbonAlias;
- (BOOL)isPathFinderAlias;
- (BOOL)isSymbolicLink;
- (BOOL)isBrokenAlias;
- (BOOL)isServerAlias;
- (BOOL)isStickyBitSet;
- (BOOL)isNetworkAutomountingSymbolicLink;
- (BOOL)isVolume;
- (BOOL)isNameLocked;

	// if your on UFS, you get a ._ path which is in appledouble format, so not good for getting the resource fork data
- (NSString*)pathToResourceFork;

- (BOOL)hasBeenModified;
- (BOOL)hasBeenRenamed;
- (NSString*)nameWhenCreated;

- (NSDate*)modificationDate;
- (NSDate*)attributeModificationDate;
- (NSDate*)creationDate;
- (NSDate*)accessDate;

- (UInt32)posixPermissions;
- (BOOL)isExecutableBitSet;
- (UInt32)posixFileMode;
- (NSString*)permissionString;

- (UInt32)ownerID;
- (NSString *)ownerName;
- (UInt32)groupID;
- (NSString *)groupName;

- (int)type;
- (int)creator;
- (int)label;
- (NSString*)comments;

- (NSArray*)directoryContents:(BOOL)visibleOnly resolveIfAlias:(BOOL)resolveIfAlias;

@end


