//
//  NTVolumeSpec.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/2/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTVolumeSpec.h"
#include <sys/param.h>
#include <sys/ucred.h>
#include <fstab.h>
#include <mach/mach_init.h>
#include <mach/mach_port.h>
#include "NTFileDesc.h"
#import "NTGetAttrList.h"
#import "NTDefaultDirectory.h"
#import "NTPathUtilities.h"

@interface NTVolumeSpec (Private)
- (NTFileDesc *)mountPointDesc;
- (void)setMountPointDesc:(NTFileDesc *)theMountPointDesc;

- (void)initVolumeInfo;
- (void)initVolumeParams;
- (void)preload;

- (FSVolumeInfo*)volumeInfo;

- (struct statfs*)statfsPtr;
- (void)setStatfsPtr:(struct statfs*)theStatfsPtr;

- (void)setCreateDate:(NSDate *)theCreateDate;
- (void)setModifyDate:(NSDate *)theModifyDate;
- (void)setBackupDate:(NSDate *)theBackupDate;
- (void)setCheckedDate:(NSDate *)theCheckedDate;

- (void)setVolumeURL:(NSURL *)theVolumeURL;
- (void)setDiskIDString:(NSString *)theDiskIDString;
- (void)setFileSystemName:(NSString *)theFileSystemName;
- (void)setMountDevice:(NSString *)theMountDevice;
- (void)setDriveInfoString:(NSString *)theDriveInfoString;

@end

@interface NTVolumeSpec (IOKit)
- (void)checkParents:(io_object_t)thing parts:(NSString**)parts;
- (NSString*)formatInterfaceInfo:(char*)device;
@end

@implementation NTVolumeSpec

+ (NTVolumeSpec*)volumeWithMountPoint:(NTFileDesc*)desc;
{
	NTVolumeSpec* result = [[NTVolumeSpec alloc] init];
	
	[result setMountPointDesc:desc];
	[result preload];
	
	return [result autorelease];
}

+ (NTVolumeSpec*)volumeWithRefNum:(FSVolumeRefNum)vRefNum;
{
	FSRef mountRef;
	OSStatus err = FSGetVolumeInfo(vRefNum, 0, nil, kFSVolInfoNone, nil, nil, &mountRef);
	
	if (!err)
		return [self volumeWithMountPoint:[NTFileDesc descFSRef:&mountRef]];
	
	return nil;
}

- (void)dealloc
{
    [self setMountPointDesc:nil];
    [self setCreateDate:nil];
    [self setModifyDate:nil];
    [self setBackupDate:nil];
    [self setCheckedDate:nil];
	
    [self setVolumeURL:nil];
    [self setDiskIDString:nil];
    [self setFileSystemName:nil];
    [self setMountDevice:nil];
    [self setDriveInfoString:nil];
	
	[self setStatfsPtr:nil];
		
    [super dealloc];
}

- (FSVolumeRefNum)volumeRefNum;
{
    return [[self mountPointDesc] volumeRefNum];
}

//---------------------------------------------------------- 
//  mountPoint 
//---------------------------------------------------------- 
- (NTFileDesc *)mountPoint
{
	NTFileDesc* mountPoint = [self mountPointDesc];
	
	// for thread safety
    return [[mountPoint retain] autorelease]; 
}

- (BOOL)isUserVolume;
{
	@synchronized(self) {
		if (!mv_bools.userVolume_initialized)
		{
			mv_bools.userVolume = ![self doNotDisplay];
			
			// not sure if this is needed, but double check (was needed in previous versions of OS X)
			if ([[self mountPointDesc] isValid] && mv_bools.userVolume)
			{
				NSString* path = [[self mountPointDesc] path];
				if ([path length])
				{
					// must fiter out /Network/Servers and /automount
					if ([path isEqualToString:@"/Network/Servers"])
						mv_bools.userVolume = NO;
					
					if ([path hasPrefix:@"/automount"])
						mv_bools.userVolume = NO;
					
					// check for volumes mounted in /Users (file vault)
					if ([[path stringByDeletingLastPathComponent] isEqualToString:[[NTDefaultDirectory sharedInstance] usersPath]])
						mv_bools.userVolume = NO;
				}
			}
			
			mv_bools.userVolume_initialized = YES;
		}
	}

	return mv_bools.userVolume;
}

//---------------------------------------------------------- 
//  volumeURL 
//---------------------------------------------------------- 
- (NSURL *)volumeURL
{
	@synchronized(self) {
		if (!mVolumeURL)
		{
			CFURLRef url;
			
			OSStatus err = FSCopyURLForVolume([self volumeRefNum], &url);
			if (!err)
			{
				[self setVolumeURL:(NSURL*)url];
				
				CFRelease(url);
			}
		}
	}
	
	return [[mVolumeURL retain] autorelease];
}

//---------------------------------------------------------- 
//  diskIDString 
//---------------------------------------------------------- 
- (NSString *)diskIDString
{
	@synchronized(self) {
		if (!mDiskIDString)
		{
			CFStringRef diskID;
			OSStatus err = FSCopyDiskIDForVolume([self volumeRefNum], &diskID);
			
			if (!err)
			{
				[self setDiskIDString:(NSString*)diskID];
			
				CFRelease(diskID);
			}
		}
	}
	
	return [[mDiskIDString retain] autorelease];
}

//---------------------------------------------------------- 
//  fileSystemName 
//---------------------------------------------------------- 
- (NSString *)fileSystemName
{
	@synchronized(self) {
		if (!mFileSystemName && [self statfsPtr])
			[self setFileSystemName:[NSString stringWithFileSystemRepresentation:[self statfsPtr]->f_fstypename]];
	}
	
	return [[mFileSystemName retain] autorelease];
}

//---------------------------------------------------------- 
//  mountDevice 
//---------------------------------------------------------- 
- (NSString *)mountDevice
{
	@synchronized(self) {
		if (!mMountDevice && [self statfsPtr])
			[self setMountDevice:[NSString stringWithFileSystemRepresentation:[self statfsPtr]->f_mntfromname]];
	}
	
	return [[mMountDevice retain] autorelease];
}

//---------------------------------------------------------- 
//  driveInfoString 
//---------------------------------------------------------- 
- (NSString *)driveInfoString
{
	@synchronized(self) {
		if (!mDriveInfoString && [self statfsPtr])
		{
			if ([self statfsPtr]->f_mntfromname[0])
			{
				// this gets the part after "/dev/"
				[self setDriveInfoString:[self formatInterfaceInfo:(char*)&[self statfsPtr]->f_mntfromname[5]]];
			}
		}
	}
	
	return [[mDriveInfoString retain] autorelease];
}

- (BOOL)isBoot;
{
    FSRef *bootRef = [NTFileDesc bootFSRef];
    
    if (bootRef && [[self mountPointDesc] FSRefPtr])
        return (FSCompareFSRefs([[self mountPointDesc] FSRefPtr], bootRef) == noErr);
	
    return NO;
}

- (BOOL)volumeAttribute:(unsigned)param;
{
	switch (param)
	{
		case bLimitFCBs:
		case bLocalWList:
		case bNoMiniFndr:
		case bNoVNEdit:
		case bNoLclSync:
		case bTrshOffLine:
		case bNoSwitchTo:
		case bNoDeskItems:
		case bNoBootBlks:
		case bAccessCntl:
		case bNoSysDir:
		case bHasExtFSVol:
		case bHasOpenDeny:
		case bHasCopyFile:
		case bHasMoveRename:
		case bHasDesktopMgr:
		case bHasShortName:
		case bHasFolderLock:
		case bHasPersonalAccessPrivileges:
		case bHasUserGroupList:
		case bHasCatSearch:
		case bHasFileIDs:
		case bHasBTreeMgr:
		case bHasBlankAccessPrivileges:
		case bSupportsAsyncRequests:
		case bSupportsTrashVolumeCache:
		case bHasDirectIO:
			[self initVolumeParams];
			
			UInt32 bitField = (1L << param);
			return ((mv_volumeAttributes & bitField) == bitField);
			break;
	}
	
	NOW_M;
	NSLog(@"Error: %d", param);
	
	return NO;
}

- (BOOL)volumeExtendedAttribute:(unsigned)param;  // add attribute like bIsEjectable
{	
	switch (param)
	{		
		case bIsEjectable:
		case bSupportsHFSPlusAPIs:
		case bSupportsFSCatalogSearch:
		case bSupportsFSExchangeObjects:
		case bSupports2TBFiles:
		case bSupportsLongNames:
		case bSupportsMultiScriptNames:
		case bSupportsNamedForks:
		case bSupportsSubtreeIterators:
		case bL2PCanMapFileBlocks:
		case bParentModDateChanges:
		case bAncestorModDateChanges:
		case bSupportsSymbolicLinks:
		case bIsAutoMounted:
		case bAllowCDiDataHandler:
		case bSupportsExclusiveLocks:
		case bSupportsJournaling:
		case bNoVolumeSizes:
		case bIsOnInternalBus:
		case bIsCaseSensitive:
		case bIsCasePreserving:
		case bDoNotDisplay:
		case bIsRemovable:
		case bNoRootTimes:
		case bIsOnExternalBus:
		case bSupportsExtendedFileSecurity:
			[self initVolumeParams];
			
			UInt32 bitField = (1L << param);
			return ((mv_volumeExtendedAttributes & bitField) == bitField);
			break;
	}
	
	NOW_M;
	NSLog(@"Error: %d", param);
	
	return NO;
}

- (CTDriveType)driveType;
{
  	@synchronized(self) {
		if (!mv_driveType)
		{
			NSString* name = [self fileSystemName];
			mv_driveType = NT_UNKNOWN_TYPE;
			
			if ([name isEqualToString:@"hfs"])
				mv_driveType = NT_HFS_TYPE;
			else if ([name isEqualToString:@"nfs"])
				mv_driveType = NT_NFS_TYPE;
			else if ([name isEqualToString:@"ufs"])
				mv_driveType = NT_UFS_TYPE;
			else if ([name isEqualToString:@"msdos"])
				mv_driveType = NT_MSDOS_TYPE;
			else if ([name isEqualToString:@"afpfs"])
				mv_driveType = NT_APPLESHARE_TYPE;
			else if ([name isEqualToString:@"webdav"])
				mv_driveType = NT_WEBDAV_TYPE;
			else if ([name isEqualToString:@"cddafs"])
				mv_driveType = NT_AUDIO_CD_TYPE;
			else if ([name isEqualToString:@"smbfs"])
				mv_driveType = NT_SAMBA_TYPE;
			else if ([name isEqualToString:@"cifs"])
				mv_driveType = NT_CIFS_TYPE;
			else if ([name isEqualToString:@"cd9660"])
				mv_driveType = NT_CDROM_TYPE;
			else if ([name isEqualToString:@"udf"])
				mv_driveType = NT_DVDROM_TYPE;
		}
	}
	
    return mv_driveType;
}

- (BOOL)isAFP
{
    return ([self driveType] == NT_APPLESHARE_TYPE);
}

- (BOOL)isHFS
{
    return ([self driveType] == NT_HFS_TYPE);
}

- (BOOL)isUFS
{
    return ([self driveType] == NT_UFS_TYPE);
}

- (BOOL)isMSDOS
{
    return ([self driveType] == NT_MSDOS_TYPE );
}

- (BOOL)isAudioCD
{
    return ([self driveType] == NT_AUDIO_CD_TYPE);
}

- (BOOL)isCDROM;
{
    return ([self driveType] == NT_CDROM_TYPE);
}

- (BOOL)isDVDROM;
{
    return ([self driveType] == NT_DVDROM_TYPE);
}

- (BOOL)isNFS
{
    return ([self driveType] == NT_NFS_TYPE);
}

// returns YES for both smb and cifs
- (BOOL)isSAMBA
{
    return ([self driveType] == NT_SAMBA_TYPE || [self driveType] == NT_CIFS_TYPE);
}

- (BOOL)isCIFS;
{
    return ([self driveType] == NT_CIFS_TYPE);
}

- (BOOL)isWebDAV
{
    return ([self driveType] == NT_WEBDAV_TYPE);
}

- (NSString*)description;
{
    return [[self mountPointDesc] description];
}

- (BOOL)isReadOnly;
{
	return ([self statfsPtr] &&
			(([self statfsPtr]->f_flags & MNT_RDONLY) != 0));
}

- (BOOL)isLocked;
{
	if (([self volumeInfo]->flags & kFSVolFlagHardwareLockedMask) != 0)
		return YES;	// volume locked by hardware
	
	if (([self volumeInfo]->flags & kFSVolFlagSoftwareLockedMask) != 0)
		return YES;	// volume locked by software
	
	return NO;
}

- (NSDate*)createDate;
{	
	@synchronized(self) {
		if (!mv_createDate)
			[self setCreateDate:[NSDate dateFromUTCDateTime:[self volumeInfo]->createDate]];
	}
    return [[mv_createDate retain] autorelease];
}

- (NSDate*)modifyDate;
{	
	@synchronized(self) {		
		if (!mv_modifyDate)
			[self setModifyDate:[NSDate dateFromUTCDateTime:[self volumeInfo]->modifyDate]];
	}
	
    return [[mv_modifyDate retain] autorelease];
}

- (NSDate*)backupDate;
{
	@synchronized(self) {
		if (!mv_backupDate)		
			[self setBackupDate:[NSDate dateFromUTCDateTime:[self volumeInfo]->backupDate]];
	}
	
    return [[mv_backupDate retain] autorelease];
}

- (NSDate*)checkedDate;
{
 	@synchronized(self) {
		if (!mv_checkedDate)
			[self setCheckedDate:[NSDate dateFromUTCDateTime:[self volumeInfo]->checkedDate]];
	}
	
    return [[mv_createDate retain] autorelease];
}

- (NSString*)volumeFormat
{	
    if ([self isHFS])
        return @"HFS+";
    else if ([self isUFS])
        return @"UFS";
    else if ([self isAFP])
        return @"AFP";
    else if ([self isMSDOS])
        return @"MS-DOS";
    else if ([self isAudioCD])
        return @"Audio CD";
    else if ([self isCDROM])
        return @"ISO9660";
    else if ([self isDVDROM])
        return @"UFS";
    else if ([self isWebDAV])
        return @"WebDAV";
    else if ([self isNFS])
        return @"NFS";
    else if ([self isCIFS])
        return @"CIFS";
    else if ([self isSAMBA])  // returns YES for both CIFS and SMB so make it after cifs
        return @"SMB";
    
    return [self fileSystemName];
}

- (BOOL)supportsSubtreeIterators;
{
    return [self volumeExtendedAttribute:bSupportsSubtreeIterators];
}

// other forks beyond data and resource fork
- (BOOL)supportsNamedForks;
{
	return [self volumeExtendedAttribute:bSupportsNamedForks];
}

- (BOOL)supportsCatalogSearch;
{
	return [self volumeExtendedAttribute:bSupportsFSCatalogSearch];
}

- (BOOL)caseSensitive;
{
	return [self volumeExtendedAttribute:bIsCaseSensitive];
}

- (BOOL)supportsSymbolicLinks;
{
	return [self volumeExtendedAttribute:bSupportsSymbolicLinks];
}

- (BOOL)supportsHFSPlusAPIs;
{
	return [self volumeExtendedAttribute:bSupportsHFSPlusAPIs];
}

- (BOOL)supportsForks;
{
	// using this to determine if the volume has ._ resource files, or real resource forks
	// supportsHFSPlusAPIs didn't work, returns YES for ._ volumes like UFS
	return [self isHFS] || [self isAFP];
}

- (BOOL)doNotDisplay;
{
	return [self volumeExtendedAttribute:bDoNotDisplay];
}

- (BOOL)isEjectable;
{
	return [self volumeExtendedAttribute:bIsEjectable];
}

- (BOOL)isExternal;
{
	return [self volumeExtendedAttribute:bIsOnExternalBus];
}

- (BOOL)supportsSearchFS;
{
	@synchronized(self) {
		if (!mv_bools.supportsSearchFS_initialized)
		{
			mv_bools.supportsSearchFS = [NTGetAttrList volumeSupportsSearchFS:[[[self mountPointDesc] path] fileSystemRepresentation]];
			
			mv_bools.supportsSearchFS_initialized = YES;
		}
    }
	
    return mv_bools.supportsSearchFS;
}

- (BOOL)isNetwork;
{
	[self initVolumeParams];
	return mv_bools.isNetworkVolume;
}

- (BOOL)isLocalFileSystem
{
	return ([self statfsPtr] &&
			(([self statfsPtr]->f_flags & MNT_LOCAL) != 0));
}

- (BOOL)isExpandrive;
{
	return [[self fileSystemName] isEqualToString:@"fusefs"];
}

@end

@implementation NTVolumeSpec (Private)

- (FSVolumeInfo*)volumeInfo;
{
	[self initVolumeInfo];
	
    return &mv_volumeInfo;
}

//---------------------------------------------------------- 
//  statfsPtr 
//---------------------------------------------------------- 
- (struct statfs*)statfsPtr
{
	@synchronized(self) {
				
		if (!mv_bools.statfs_initialized)
		{
			if ([[[self mountPointDesc] path] length])
			{
				struct statfs* theStatfsPtr = calloc(1, sizeof(struct statfs));
				
				if (statfs([[self mountPointDesc] fileSystemPath], theStatfsPtr) == 0)
					[self setStatfsPtr:theStatfsPtr];
				else
					free(theStatfsPtr);
			}
			
			mv_bools.statfs_initialized = YES;
		}
	}
	
    return mStatfsPtr;
}

- (void)setStatfsPtr:(struct statfs*)theStatfsPtr
{
	if (mStatfsPtr)
	{
		free(mStatfsPtr);
		mStatfsPtr = nil;
	}
	
    mStatfsPtr = theStatfsPtr;
}

- (void)initVolumeInfo;
{
	@synchronized(self) {
		if (!mv_bools.volumeInfo_initialized)
		{
			OSStatus err = FSGetVolumeInfo([[self mountPointDesc] volumeRefNum], 0, nil, kFSVolInfoGettableInfo, &mv_volumeInfo, nil, nil);
			if (!err)
				;
			
			mv_bools.volumeInfo_initialized = YES;
		}
    }
}

- (void)initVolumeParams;
{
	@synchronized(self) {
		if (!mv_bools.volumeParams_initialized)
		{
			GetVolParmsInfoBuffer volumeParams;
			
			OSStatus err = FSGetVolumeParms([self volumeRefNum], &volumeParams, sizeof(GetVolParmsInfoBuffer));
			if (!err)
			{
				mv_volumeAttributes = volumeParams.vMAttrib;
				mv_volumeExtendedAttributes = (volumeParams.vMVersion >= 3) ? volumeParams.vMExtendedAttributes : 0;
				mv_bools.isNetworkVolume = (volumeParams.vMServerAdr != 0);
				
				// SNG hack for macfuse
				if (!mv_bools.isNetworkVolume)
					mv_bools.isNetworkVolume = [self isExpandrive];
			}
			
			mv_bools.volumeParams_initialized = YES;
		}
    }
}

//---------------------------------------------------------- 
//  mountPointDesc 
//---------------------------------------------------------- 
- (NTFileDesc *)mountPointDesc
{
    return mMountPointDesc; 
}

- (void)setMountPointDesc:(NTFileDesc *)theMountPointDesc
{
    if (mMountPointDesc != theMountPointDesc) {
        [mMountPointDesc release];
        mMountPointDesc = [theMountPointDesc retain];
    }
}

- (void)setCreateDate:(NSDate *)theCreateDate
{
    if (mv_createDate != theCreateDate) {
        [mv_createDate release];
        mv_createDate = [theCreateDate retain];
    }
}

- (void)setModifyDate:(NSDate *)theModifyDate
{
    if (mv_modifyDate != theModifyDate) {
        [mv_modifyDate release];
        mv_modifyDate = [theModifyDate retain];
    }
}

- (void)setBackupDate:(NSDate *)theBackupDate
{
    if (mv_backupDate != theBackupDate) {
        [mv_backupDate release];
        mv_backupDate = [theBackupDate retain];
    }
}

- (void)setCheckedDate:(NSDate *)theCheckedDate
{
    if (mv_checkedDate != theCheckedDate) {
        [mv_checkedDate release];
        mv_checkedDate = [theCheckedDate retain];
    }
}

- (void)preload;
{
	[self initVolumeInfo];
	[self statfsPtr]; // loads statfs info
	[self initVolumeParams];
	
	[[self mountPointDesc] displayName];
	[[self mountPointDesc] icon];
}

- (void)setVolumeURL:(NSURL *)theVolumeURL
{
    if (mVolumeURL != theVolumeURL) {
        [mVolumeURL release];
        mVolumeURL = [theVolumeURL retain];
    }
}

- (void)setDiskIDString:(NSString *)theDiskIDString
{
    if (mDiskIDString != theDiskIDString) {
        [mDiskIDString release];
        mDiskIDString = [theDiskIDString retain];
    }
}

- (void)setFileSystemName:(NSString *)theFileSystemName
{
    if (mFileSystemName != theFileSystemName) {
        [mFileSystemName release];
        mFileSystemName = [theFileSystemName retain];
    }
}

- (void)setMountDevice:(NSString *)theMountDevice
{
    if (mMountDevice != theMountDevice) {
        [mMountDevice release];
        mMountDevice = [theMountDevice retain];
    }
}

- (void)setDriveInfoString:(NSString *)theDriveInfoString
{
    if (mDriveInfoString != theDriveInfoString) {
        [mDriveInfoString release];
        mDriveInfoString = [theDriveInfoString retain];
    }
}

@end

@implementation NTVolumeSpec (NTVolumeDescInfo)

- (UInt32)fileCount;
{	
	return [self volumeInfo]->fileCount;
}

- (UInt32)folderCount;
{	
	return [self volumeInfo]->folderCount;
}

- (UInt64)totalBytes;
{	
	return [self volumeInfo]->totalBytes;
}

- (UInt64)freeBytes;
{	
	return [self volumeInfo]->freeBytes;
}

- (UInt32)blockSize;
{	
	return [self volumeInfo]->blockSize;
}

- (UInt32)totalBlocks;
{	
	return [self volumeInfo]->totalBlocks;
}

- (UInt32)freeBlocks;
{	
	return [self volumeInfo]->freeBlocks;
}

- (UInt32)nextAllocation;
{	
	return [self volumeInfo]->nextAllocation;
}

- (UInt32)rsrcClumpSize;
{	
	return [self volumeInfo]->rsrcClumpSize;
}

- (UInt32)dataClumpSize;
{	
	return [self volumeInfo]->dataClumpSize;
}

- (UInt32)nextCatalogID;
{	
	return [self volumeInfo]->nextCatalogID;
}

- (UInt16)flags;
{	
	return [self volumeInfo]->flags;
}

- (UInt16)filesystemID;
{	
	return [self volumeInfo]->filesystemID;
}

- (UInt16)signature;
{	
	return [self volumeInfo]->signature;
}

- (UInt16)driveNumber;
{	
	return [self volumeInfo]->driveNumber;
}

- (short)driverRefNum;
{	
	return [self volumeInfo]->driverRefNum;
}

@end

@implementation NTVolumeSpec (IOKit)

- (void)checkParents:(io_object_t)thing parts:(NSString**)parts;
{
    CFMutableDictionaryRef props;
    NSString* value;
    io_object_t nextParent=0;
    io_iterator_t parentsIterator=0;
    kern_return_t kernResult;
    kernResult = IORegistryEntryGetParentIterator(thing,kIOServicePlane,&parentsIterator);
    
    if ((kernResult == KERN_SUCCESS) && parentsIterator) 
    {
        while ((nextParent = IOIteratorNext(parentsIterator))) 
        {
            kernResult = IORegistryEntryCreateCFProperties(nextParent,&props,kCFAllocatorDefault,0);
            
            if (kernResult==KERN_SUCCESS) 
            {                     
				// must [[value retain] autorelease] value since we delete the dictionary before returning!!
                if (CFDictionaryGetValueIfPresent(props,@"Model",(const void**)&value))
                    parts[0] = [[[value retain] autorelease] uppercaseString];
                if (CFDictionaryGetValueIfPresent(props,@"Revision",(const void**)&value)) 
                    parts[1] = [[value retain] autorelease];
				
				if (!parts[0] || !parts[1])
					[self checkParents:nextParent parts:parts];
                
                CFRelease(props);
            }
            
            IOObjectRelease(nextParent);
        }
		
		IOObjectRelease(parentsIterator);
    }
}

- (NSString*)formatInterfaceInfo:(char*)device;
{
    NSString* result=nil;
    NSString* parts[5]={nil,nil,nil,nil,nil};
    io_iterator_t mediaIterator=0;
    io_object_t firstMedia=0;
    kern_return_t kernResult;
    int i;
    CFMutableDictionaryRef classesToMatch;
    
	classesToMatch = IOBSDNameMatching(kIOMasterPortDefault,0,device);
	if (classesToMatch) 
	{
		kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatch, &mediaIterator);
		if ((kernResult == KERN_SUCCESS) && mediaIterator)
		{
			firstMedia = IOIteratorNext(mediaIterator);
			
			if (firstMedia) 
			{
				[self checkParents:firstMedia parts:parts];
				for (i=0;i<5;i++)
				{
					if (parts[i] && [parts[i] length])
					{
						NSString* str = [parts[i] stringByTrimmingWhiteSpace];
						
						if (result)
							result = [result stringByAppendingFormat:@" %@", str];
						else 
							result = str;
					}
				}
				
				IOObjectRelease(firstMedia);
			}
			
			IOObjectRelease(mediaIterator);
		}
	}
    
    return result ? result:@"<unknown interface>";
}

@end

