//
//  NTVolume.m

#import "NTVolume.h"
#include <sys/param.h>
#include <sys/ucred.h>
#include <fstab.h>
#include <mach/mach_init.h>
#include <mach/mach_port.h>
#include "NTFileDesc.h"
#import "NTGetAttrList.h"
#import "NTVolumeSpec.h"
#import "NTVolumeNotificationMgr.h"
#import "NTVolumeMgr.h"

@interface NTVolume (Private)
- (NTVolumeSpec*)volumeSpec;
- (void)setVolumeRefNum:(FSVolumeRefNum)theVolumeRefNum;
@end

@implementation NTVolume

+ (NTVolume*)volumeWithRefNum:(FSVolumeRefNum)vRefNum;
{
	NTVolume* result = [[NTVolume alloc] init];
	
	[result setVolumeRefNum:vRefNum];
	
	return [result autorelease];
}

- (FSVolumeRefNum)volumeRefNum;
{
    return mv_volumeRefNum;
}

//---------------------------------------------------------- 
//  mountPoint 
//---------------------------------------------------------- 
- (NTFileDesc *)mountPoint
{
    return [[self volumeSpec] mountPoint]; 
}

- (NSURL*)volumeURL;
{
    return [[self volumeSpec] volumeURL]; 
}

- (BOOL)isBoot;
{
    return [[self volumeSpec] isBoot]; 
}

- (BOOL)volumeAttribute:(unsigned)param;
{
    return [[self volumeSpec] volumeAttribute:param]; 
}

- (BOOL)volumeExtendedAttribute:(unsigned)param;  // add attribute like bIsEjectable
{	
    return [[self volumeSpec] volumeExtendedAttribute:param]; 
}

- (NSString*)mountDevice;
{	
    return [[self volumeSpec] mountDevice]; 
}

- (NSString *)fileSystemName
{	
    return [[self volumeSpec] fileSystemName]; 
}

- (NSString *)diskIDString;
{
    return [[self volumeSpec] diskIDString]; 
}

- (CTDriveType)driveType;
{
    return [[self volumeSpec] driveType]; 
}

- (BOOL)isAFP
{
    return [[self volumeSpec] isAFP]; 
}

- (BOOL)isHFS
{
    return [[self volumeSpec] isHFS]; 
}

- (BOOL)isUFS
{
    return [[self volumeSpec] isUFS]; 
}

- (BOOL)isMSDOS
{
    return [[self volumeSpec] isMSDOS]; 
}

- (BOOL)isAudioCD
{
    return [[self volumeSpec] isAudioCD]; 
}

- (BOOL)isCDROM;
{
    return [[self volumeSpec] isCDROM]; 
}

- (BOOL)isDVDROM;
{
    return [[self volumeSpec] isDVDROM]; 
}

- (BOOL)isNFS
{
    return [[self volumeSpec] isNFS]; 
}

// returns YES for both smb and cifs
- (BOOL)isSAMBA
{
    return [[self volumeSpec] isSAMBA]; 
}

- (BOOL)isCIFS;
{
    return [[self volumeSpec] isCIFS]; 
}

- (BOOL)isWebDAV
{
    return [[self volumeSpec] isWebDAV]; 
}

- (NSString*)description;
{
    return [[self volumeSpec] description]; 
}

- (BOOL)isReadOnly;
{
    return [[self volumeSpec] isReadOnly]; 
}

- (BOOL)isLocked;
{
    return [[self volumeSpec] isLocked]; 
}

- (NSDate*)createDate;
{	
    return [[self volumeSpec] createDate]; 
}

- (NSDate*)modifyDate;
{	
    return [[self volumeSpec] modifyDate]; 
}

- (NSDate*)backupDate;
{
    return [[self volumeSpec] backupDate]; 
}

- (NSDate*)checkedDate;
{
    return [[self volumeSpec] checkedDate]; 
}

- (NSString*)driveInfoString;
{
    return [[self volumeSpec] driveInfoString]; 
}

- (NSString*)volumeFormat
{	
    return [[self volumeSpec] volumeFormat]; 
}

- (BOOL)caseSensitive;
{
	return [[self volumeSpec] caseSensitive]; 
}

- (BOOL)supportsSubtreeIterators;
{
    return [[self volumeSpec] supportsSubtreeIterators]; 
}

// other forks beyond data and resource fork
- (BOOL)supportsNamedForks;
{
    return [[self volumeSpec] supportsNamedForks]; 
}

- (BOOL)supportsForks; // traditional rsrc/data forks
{
    return [[self volumeSpec] supportsForks]; 
}

- (BOOL)supportsCatalogSearch;
{
    return [[self volumeSpec] supportsCatalogSearch]; 
}

- (BOOL)supportsSymbolicLinks;
{
    return [[self volumeSpec] supportsSymbolicLinks]; 
}

- (BOOL)supportsHFSPlusAPIs;
{
    return [[self volumeSpec] supportsHFSPlusAPIs]; 
}

- (BOOL)doNotDisplay;
{
    return [[self volumeSpec] doNotDisplay]; 
}

- (BOOL)isEjectable;
{
    return [[self volumeSpec] isEjectable]; 
}

- (BOOL)isExternal;
{
    return [[self volumeSpec] isExternal]; 
}

- (BOOL)supportsSearchFS;
{
    return [[self volumeSpec] supportsSearchFS]; 
}

- (BOOL)isNetwork;
{
    return [[self volumeSpec] isNetwork]; 
}

- (BOOL)isLocalFileSystem
{
	return [[self volumeSpec] isLocalFileSystem]; 
}

@end

@implementation NTVolume (Utilities)

+ (UInt64)totalBytes_everyVolume;
{
    UInt64 result=0;
	
	NSEnumerator *enumerator = [[[NTVolumeMgr sharedInstance] volumeSpecs] objectEnumerator];
	NTVolumeSpec* volume;

	while (volume = [enumerator nextObject])
	{
		if (![volume isNetwork])
			result += [volume totalBytes];
	}
	
    return result;
}

+ (UInt64)freeBytes_everyVolume;
{
    UInt64 result=0;
    
	NSEnumerator *enumerator = [[[NTVolumeMgr sharedInstance] volumeSpecs] objectEnumerator];
	NTVolumeSpec* volume;
	
	while (volume = [enumerator nextObject])
	{
		if (![volume isNetwork])
			result += [volume freeBytes];
	}
	
	return result;
}

@end

@implementation NTVolume (NTVolumeInfo)

- (UInt32)fileCount;
{	
    return [[self volumeSpec] fileCount]; 
}

- (UInt32)folderCount;
{	
    return [[self volumeSpec] folderCount]; 
}

- (UInt64)totalBytes;
{	
    return [[self volumeSpec] totalBytes]; 
}

- (UInt64)freeBytes;
{	
    return [[self volumeSpec] freeBytes]; 
}

- (UInt32)blockSize;
{	
    return [[self volumeSpec] blockSize]; 
}

- (UInt32)totalBlocks;
{	
    return [[self volumeSpec] totalBlocks]; 
}

- (UInt32)freeBlocks;
{	
    return [[self volumeSpec] freeBlocks]; 
}

- (UInt32)nextAllocation;
{	
    return [[self volumeSpec] nextAllocation]; 
}

- (UInt32)rsrcClumpSize;
{	
    return [[self volumeSpec] rsrcClumpSize]; 
}

- (UInt32)dataClumpSize;
{	
    return [[self volumeSpec] dataClumpSize]; 
}

- (UInt32)nextCatalogID;
{	
    return [[self volumeSpec] nextCatalogID]; 
}

- (UInt16)flags;
{	
    return [[self volumeSpec] flags]; 
}

- (UInt16)filesystemID;
{	
    return [[self volumeSpec] filesystemID]; 
}

- (UInt16)signature;
{	
    return [[self volumeSpec] signature]; 
}

- (UInt16)driveNumber;
{	
    return [[self volumeSpec] driveNumber]; 
}

- (short)driverRefNum;
{	
    return [[self volumeSpec] driverRefNum]; 
}

@end

@implementation NTVolume (Private)

- (NTVolumeSpec*)volumeSpec;
{
	return [[NTVolumeMgr sharedInstance] volumeSpecForRefNum:[self volumeRefNum]];
}

//---------------------------------------------------------- 
//  volumeRefNum 
//---------------------------------------------------------- 
- (FSVolumeRefNum)volumeRefNum
{
    return mv_volumeRefNum;
}

- (void)setVolumeRefNum:(FSVolumeRefNum)theVolumeRefNum
{
    mv_volumeRefNum = theVolumeRefNum;
}

@end

