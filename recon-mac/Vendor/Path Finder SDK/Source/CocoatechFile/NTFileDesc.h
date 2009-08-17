//
//  NTFileDesc.h
//  CocoatechFile
//
//  Created by sgehrman on Sun Jul 15 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTVolume, NTFileDescData, NTMetadata, NSDate, NTIcon, NTFSRefObject, NTVolumeMgrState, NTFileDesc, NTFileTypeIdentifier;

@interface NTFileDesc : NSObject <NSCoding>
{    	
	NTFileDescData* cache;
	NTFSRefObject* FSRefObject;
    NTVolumeMgrState *volumeMgrState;

	BOOL mv_valid;
	BOOL mv_isComputer;
}

@property (retain, nonatomic) NTFileDescData* cache;
@property (retain, nonatomic) NTFSRefObject* FSRefObject;
@property (retain, nonatomic) NTVolumeMgrState *volumeMgrState;

- (id)initWithPath:(NSString *)path;
- (id)initWithFSRefObject:(NTFSRefObject*)refObject;

    // returns the resolved NTFileDesc if it's an alias
- (NTFileDesc*)descResolveIfAlias;
- (NTFileDesc*)descResolveIfAlias:(BOOL)resolveIfServerAlias;
- (NTFileDesc*)aliasDesc; // if we were resolved from an alias, this is the original alias file
- (NTFileDesc*)newDesc;  // creates a new copy of the desc (resets mod dates, displayname etc)

- (NTIcon*)icon;

- (BOOL)isValid;
- (BOOL)stillExists;
- (BOOL)isComputer;

	// is the directory or file open
- (BOOL)isOpen;

- (NSPoint)finderPosition;
- (NSString*)versionString;
- (NSString*)bundleVersionString;
- (NSString*)bundleIdentifier;
- (NSString*)infoString;
- (NSString*)itemInfo;
- (NSString*)uniformTypeID;

- (NSString *)path;
- (NSString*)displayPath; // path, or Computer for @"", or boot volumes name for "/"
- (NSArray*)FSRefPath:(BOOL)includeSelf; // an array of FSRefObjects
- (NTMetadata*)metadata;

    // an array of FileDescs - strips out /Volume automatically
- (NSArray*)pathComponents:(BOOL)resolveAliases;

- (NSURL*)URL;
- (const char *)fileSystemPath;
- (const char *)UTF8Path;

- (FSRef*)FSRefPtr;

- (UInt32)nodeID;
- (NSString *)name;
- (NSString*)displayName;
- (NSString *)extension;
- (NTFileDesc *)application;
- (NSString*)executablePath;

- (NSString*)dictionaryKey;
- (NSString*)strictDictionaryKey; // like dictionaryKey, but adds the parentDirID so you can know if the item moved for example

- (NSString*)bundleSignature;

- (NTFileDesc *)parentDesc;
- (UInt32)parentDirID;
- (BOOL)parentIsVolume;
- (NSString *)parentPath:(BOOL)forDisplay;

- (NTVolume*)volume;
- (FSVolumeRefNum)volumeRefNum;

- (NSString *)kindString;
- (NSString *)architecture;
- (NTFileTypeIdentifier*)typeIdentifier;

- (UInt64)size; // returns total size for files
- (UInt64)physicalSize; // returns total physical size for files

- (UInt64)rsrcForkSize;
- (UInt64)dataForkSize;
- (UInt64)rsrcForkPhysicalSize;
- (UInt64)dataForkPhysicalSize;

- (UInt32)valence;  // only valid for folders, 0 if file or invalid

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
- (BOOL)isPipe;
- (BOOL)isVolume;
- (BOOL)isNameLocked;

- (BOOL)catalogInfo:(FSCatalogInfo*)outCatalogInfo bitmap:(FSCatalogInfoBitmap)bitmap;

// if your on UFS, you get a ._ path which is in appledouble format, so not good for getting the resource fork data
- (NSString*)pathToResourceFork;

- (BOOL)hasBeenModified;
- (BOOL)hasBeenRenamed;
- (NSString*)nameWhenCreated;

- (NSDate*)modificationDate;
- (NSDate*)attributeModificationDate;
- (NSDate*)creationDate;
- (NSDate*)accessDate;
- (NSDate*)lastUsedDate;

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

- (const FileInfo*)fileInfo;

- (BOOL)applicationCanOpenFile:(NTFileDesc*)file;

- (BOOL)isParentOfDesc:(NTFileDesc*)desc;  // used to determine if NTFileDesc is contained by this directory
- (BOOL)isParentOfFSRef:(FSRef*)fsRefPtr;  // used to determine if FSRef is contained by this directory
- (BOOL)isParentOfRefPath:(NSArray*)fsRefPath;  // used to determine if FSRef is contained by this directory

    // debugging tools
- (NSString*)description;
- (NSString*)longDescription;

@end

@interface NTFileDesc (NTVolume)

- (BOOL)isVolumeReadOnly;
- (BOOL)isBootVolume;
- (BOOL)isExternal;
- (BOOL)isNetwork;
- (BOOL)isLocalFileSystem;
- (BOOL)isSlowVolume;  // DVD, CD, Network
- (BOOL)isEjectable;
- (NTFileDesc *)mountPoint;
@end

@interface NTFileDesc (Setters)

// the name to display to the user for a rename command
- (NSString*)displayNameForRename;

// changes contents to new FSRef after rename (if FSRef changes which it does in some cases on rename)
- (NSString*)rename:(NSString*)newName err:(OSStatus*)outErr;

@end

// ================================================================================================================

// type and creator of a Path Finder document
#define kPathFinderAliasExtension @"path"

