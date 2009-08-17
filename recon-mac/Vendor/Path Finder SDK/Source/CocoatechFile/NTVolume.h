//
//  NTVolume.h

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#include <sys/mount.h>

@class NTFileDesc;

typedef enum
{
    NT_UNKNOWN_TYPE=1,
    NT_HFS_TYPE,
    NT_NFS_TYPE,
    NT_UFS_TYPE,
    NT_MSDOS_TYPE,
    NT_APPLESHARE_TYPE,
    NT_SAMBA_TYPE,
    NT_CIFS_TYPE,
    NT_WEBDAV_TYPE,
    NT_AUDIO_CD_TYPE,
    NT_CDROM_TYPE,
    NT_DVDROM_TYPE

} CTDriveType;

@interface NTVolume : NSObject
{
	FSVolumeRefNum mv_volumeRefNum;
}

+ (NTVolume*)volumeWithRefNum:(FSVolumeRefNum)vRefNum;

- (FSVolumeRefNum)volumeRefNum;

- (BOOL)isLocked;
- (BOOL)isReadOnly;

- (BOOL)isBoot;
- (BOOL)isExternal;  // firewire or USB volume?
- (BOOL)isNetwork;
- (BOOL)isLocalFileSystem;

- (BOOL)isEjectable;
- (BOOL)caseSensitive;
- (BOOL)supportsSubtreeIterators;
- (BOOL)supportsForks; // traditional rsrc/data forks
- (BOOL)supportsNamedForks;
- (BOOL)supportsCatalogSearch;
- (BOOL)supportsSymbolicLinks;
- (BOOL)supportsHFSPlusAPIs;
- (BOOL)doNotDisplay;
- (BOOL)supportsSearchFS;

- (NTFileDesc*)mountPoint;

- (BOOL)volumeAttribute:(unsigned)param;  // add attribute like bLimitFCBs
- (BOOL)volumeExtendedAttribute:(unsigned)param;  // add attribute like bIsEjectable

- (NSDate *)createDate;
- (NSDate *)modifyDate;
- (NSDate *)backupDate;
- (NSDate *)checkedDate;

- (NSURL *)volumeURL;
- (CTDriveType)driveType;
- (NSString *)diskIDString;
- (NSString *)fileSystemName;
- (NSString *)mountDevice;
- (NSString *)driveInfoString;

- (NSString*)volumeFormat;

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
	
@interface NTVolume (Utilities)

+ (UInt64)totalBytes_everyVolume;
+ (UInt64)freeBytes_everyVolume;

@end

@interface NTVolume (NTVolumeInfo)

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