//
//  NTVolumeSpec.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/2/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#include <sys/mount.h>
#import "NTVolume.h"

@class NTFileDesc;

@interface NTVolumeSpec : NSObject
{
	NTFileDesc* mMountPointDesc;
	
    FSVolumeInfo mv_volumeInfo;
	
    struct statfs* mStatfsPtr;  // stays nil if statfs fails for some reason
	
    CTDriveType	mv_driveType;	
	
	NSURL* mVolumeURL;
    NSString* mDiskIDString;
    NSString* mFileSystemName;
    NSString* mMountDevice;
	NSString* mDriveInfoString;
	
    NSDate* mv_createDate;
    NSDate* mv_modifyDate;
    NSDate* mv_backupDate;
    NSDate* mv_checkedDate;
	
	UInt32 mv_volumeAttributes;
	UInt32 mv_volumeExtendedAttributes;
	
	struct {		
		// volume params where we get mv_volumeAttributes and mv_volumeExtendedAttributes
		unsigned int        volumeParams_initialized:1;
		unsigned int        isNetworkVolume:1;
		// sets mv_volumeAttributes
		// sets mv_volumeExtendedAttributes
		
		// volume params from getattrlist
		unsigned int        supportsSearchFS_initialized:1;
		unsigned int        supportsSearchFS:1;
		
		// BOOLs from FSVolumeInfo
		unsigned int        volumeInfo_initialized:1;
		unsigned int        statfs_initialized:1;

		unsigned int        userVolume:1;
		unsigned int        userVolume_initialized:1;

	} mv_bools;
}

+ (NTVolumeSpec*)volumeWithMountPoint:(NTFileDesc*)desc;
+ (NTVolumeSpec*)volumeWithRefNum:(FSVolumeRefNum)vRefNum;

- (BOOL)isUserVolume;

- (BOOL)isLocked;
- (BOOL)isReadOnly;

- (BOOL)isBoot;
- (BOOL)isExternal;  // firewire or USB volume?
- (BOOL)isNetwork;
- (BOOL)isLocalFileSystem;
- (BOOL)isExpandrive;

- (BOOL)isEjectable;
- (BOOL)caseSensitive;
- (BOOL)supportsSubtreeIterators;
- (BOOL)supportsForks; // traditional rsrc/data forks
- (BOOL)supportsNamedForks;  // other named forks
- (BOOL)supportsCatalogSearch;
- (BOOL)supportsSymbolicLinks;
- (BOOL)supportsHFSPlusAPIs;
- (BOOL)doNotDisplay;
- (BOOL)supportsSearchFS;

- (FSVolumeRefNum)volumeRefNum;
- (NTFileDesc*)mountPoint;

- (BOOL)volumeAttribute:(unsigned)param;  // add attribute like bLimitFCBs
- (BOOL)volumeExtendedAttribute:(unsigned)param;  // add attribute like bIsEjectable

- (NSDate *)createDate;
- (NSDate *)modifyDate;
- (NSDate *)backupDate;
- (NSDate *)checkedDate;

- (CTDriveType)driveType;

- (NSString*)volumeFormat;

- (NSURL *)volumeURL;
- (NSString *)diskIDString;
- (NSString *)fileSystemName;
- (NSString *)mountDevice;
- (NSString *)driveInfoString;

- (BOOL)isHFS;
- (BOOL)isUFS;
- (BOOL)isMSDOS;
- (BOOL)isNFS;
- (BOOL)isAudioCD;
- (BOOL)isCDROM;
- (BOOL)isDVDROM;
- (BOOL)isAFP;
- (BOOL)isSAMBA; // true for both smb and cifs
- (BOOL)isCIFS;
- (BOOL)isWebDAV;

@end

@interface NTVolumeSpec (NTVolumeDescInfo)

- (UInt32)fileCount;
- (UInt32)folderCount;
- (UInt64)totalBytes;
- (UInt64)freeBytes;
- (UInt32)blockSize;
- (UInt32)totalBlocks;
- (UInt32)freeBlocks;
- (UInt32)nextAllocation;
- (UInt32)rsrcClumpSize;
- (UInt32)dataClumpSize;
- (UInt32)nextCatalogID;
- (UInt16)flags;
- (UInt16)filesystemID;
- (UInt16)signature;
- (UInt16)driveNumber;
- (short)driverRefNum;

@end