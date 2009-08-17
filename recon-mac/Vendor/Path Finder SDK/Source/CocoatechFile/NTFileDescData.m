//
//  NTFileDescData.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/24/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFileDescData.h"
#import "NTFileDescData-Private.h"

@interface NTFileDescData ()
@property (retain, nonatomic) NSString* cachedDisplayName;
@property (retain, nonatomic) NSString* cachedKind;
@property (retain, nonatomic) NSString* cachedArchitecture;
@property (retain, nonatomic) NSString* cachedExtension;
@property (retain, nonatomic) NTIcon* cachedIcon;
@property (retain, nonatomic) NSDate* cachedModificationDate;
@property (retain, nonatomic) NSDate* cachedAttributeDate;
@property (retain, nonatomic) NSDate* cachedAccessDate;
@property (retain, nonatomic) NSDate* cachedLastUsedDate;
@property (retain, nonatomic) NSDate* cachedCreationDate;
@property (retain, nonatomic) NSString* cachedVersion;
@property (retain, nonatomic) NSString* cachedBundleVersion;
@property (retain, nonatomic) NSString* cachedGetInfo;
@property (retain, nonatomic) NTFileDesc* cachedApplication;
@property (retain, nonatomic) NSString* cachedComments;
@property (retain, nonatomic) NSString* cachedDictionaryKey;
@property (retain, nonatomic) NSString* cachedStrictDictionaryKey;
@property (retain, nonatomic) NSString* cachedPermissionString;
@property (retain, nonatomic) NSString* cachedOwnerName;
@property (retain, nonatomic) NSString* cachedGroupName;
@property (retain, nonatomic) NSString* cachedUniformTypeID;
@property (retain, nonatomic) NSString* cachedBundleSignature;
@property (retain, nonatomic) NSString* cachedBundleIdentifier;
@property (retain, nonatomic) NSString* cachedItemInfo;
@property (retain, nonatomic) NTVolume* cachedVolume;
@property (retain, nonatomic) NTFileTypeIdentifier* cachedTypeIdentifier;
@property (assign, nonatomic) UInt32 cachedPosixPermissions;
@property (assign, nonatomic) UInt32 cachedPosixFileMode;
@property (assign, nonatomic) FSVolumeRefNum cachedVRefNum;
@property (assign, nonatomic) UInt32 cachedValence;
@property (assign, nonatomic) UInt64 cachedFileSize;
@property (assign, nonatomic) UInt64 cachedPhysicalFileSize;
@property (assign, nonatomic) UInt64 cachedRsrcForkSize;
@property (assign, nonatomic) UInt64 cachedDataForkSize;
@property (assign, nonatomic) UInt64 cachedRsrcForkPhysicalSize;
@property (assign, nonatomic) UInt64 cachedDataForkPhysicalSize;
@property (retain, nonatomic) NTMetadata *cachedMetadata;
@property (retain, nonatomic) NTFileDesc* cachedResolvedDesc;
@property (assign, nonatomic) UInt32 cachedType;
@property (assign, nonatomic) UInt32 cachedCreator;
@property (assign, nonatomic) UInt32 cachedLabel;
@property (assign, nonatomic) UInt32 cachedGroupID;
@property (assign, nonatomic) UInt32 cachedOwnerID;
@property (assign, nonatomic) UInt32 cachedNodeID;
@property (assign, nonatomic) UInt32 cachedParentDirID;
@property (retain, nonatomic) NSString* cachedOriginalAliasFilePath;
@end

@implementation NTFileDescData

@synthesize cachedDisplayName;
@synthesize cachedKind;
@synthesize cachedArchitecture;
@synthesize cachedExtension;
@synthesize cachedIcon;
@synthesize cachedModificationDate;
@synthesize cachedAttributeDate;
@synthesize cachedAccessDate;
@synthesize cachedLastUsedDate;
@synthesize cachedCreationDate;
@synthesize cachedVersion;
@synthesize cachedBundleVersion;
@synthesize cachedGetInfo;
@synthesize cachedApplication;
@synthesize cachedComments;
@synthesize cachedDictionaryKey, cachedStrictDictionaryKey;
@synthesize cachedPermissionString;
@synthesize cachedOwnerName;
@synthesize cachedGroupName;
@synthesize cachedUniformTypeID;
@synthesize cachedBundleSignature;
@synthesize cachedBundleIdentifier;
@synthesize cachedItemInfo;
@synthesize cachedVolume;
@synthesize cachedTypeIdentifier;
@synthesize cachedPosixPermissions;
@synthesize cachedPosixFileMode;
@synthesize cachedVRefNum;
@synthesize cachedValence;
@synthesize cachedFileSize;
@synthesize cachedPhysicalFileSize;
@synthesize cachedRsrcForkSize;
@synthesize cachedDataForkSize;
@synthesize cachedRsrcForkPhysicalSize;
@synthesize cachedDataForkPhysicalSize;
@synthesize cachedMetadata;
@synthesize cachedResolvedDesc;
@synthesize cachedType;
@synthesize cachedCreator;
@synthesize cachedLabel;
@synthesize cachedGroupID;
@synthesize cachedOwnerID;
@synthesize cachedNodeID;
@synthesize cachedParentDirID;
@synthesize cachedOriginalAliasFilePath;

+ (NTFileDescData *)cache;
{
	NTFileDescData* result = [[NTFileDescData alloc] init];
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
    self.cachedDisplayName = nil;
    self.cachedKind = nil;
    self.cachedArchitecture = nil;
    self.cachedExtension = nil;
    self.cachedIcon = nil;
    self.cachedModificationDate = nil;
    self.cachedAttributeDate = nil;
    self.cachedAccessDate = nil;
    self.cachedLastUsedDate = nil;
    self.cachedCreationDate = nil;
    self.cachedVersion = nil;
    self.cachedBundleVersion = nil;
    self.cachedGetInfo = nil;
    self.cachedApplication = nil;
    self.cachedComments = nil;
    self.cachedDictionaryKey = nil;
    self.cachedStrictDictionaryKey = nil;
    self.cachedPermissionString = nil;
    self.cachedOwnerName = nil;
    self.cachedGroupName = nil;
    self.cachedUniformTypeID = nil;
    self.cachedBundleSignature = nil;
    self.cachedBundleIdentifier = nil;
    self.cachedItemInfo = nil;
    self.cachedVolume = nil;
    self.cachedTypeIdentifier = nil;
    self.cachedMetadata = nil;
    self.cachedResolvedDesc = nil;
    self.cachedOriginalAliasFilePath = nil;
    [super dealloc];
}

//---------------------------------------------------------- 
//  displayName 
//---------------------------------------------------------- 

- (BOOL)displayName_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_displayName_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedDisplayName];
		}
	}
	
	return result;
}

- (void)setDisplayName:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_displayName_initialized)
		{
			mv_flags.mv_displayName_initialized = YES;
			[self setCachedDisplayName:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  isFile
//---------------------------------------------------------- 

- (BOOL)isFile_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isFile_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsFile];
		}
	}
	
	return result;	
}

- (void)setIsFile:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isFile_initialized)
		{
			mv_flags.mv_isFile_initialized = YES;
			[self setCachedIsFile:value];
		}
	}	
}

//---------------------------------------------------------- 
//  kind
//---------------------------------------------------------- 

- (BOOL)kind_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_kind_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedKind];
		}
	}
	
	return result;
}

- (void)setKind:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_kind_initialized)
		{
			mv_flags.mv_kind_initialized = YES;
			[self setCachedKind:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}		
	}
}

//---------------------------------------------------------- 
//  architecture
//---------------------------------------------------------- 

- (BOOL)architecture_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_architecture_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedArchitecture];
		}
	}
	
	return result;
}

- (void)setArchitecture:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_architecture_initialized)
		{
			mv_flags.mv_architecture_initialized = YES;
			[self setCachedArchitecture:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}		
	}
}

//---------------------------------------------------------- 
//  extension
//---------------------------------------------------------- 

- (BOOL)extension_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_extension_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedExtension];
		}
	}
	
	return result;
}

- (void)setExtension:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_extension_initialized)
		{
			mv_flags.mv_extension_initialized = YES;
			[self setCachedExtension:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}		
	}
}

//---------------------------------------------------------- 
//  icon
//---------------------------------------------------------- 

- (BOOL)icon_initialized:(NTIcon**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_icon_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIcon];
		}
	}
	
	return result;
}

- (void)setIcon:(NTIcon*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_icon_initialized)
		{
			mv_flags.mv_icon_initialized = YES;
			[self setCachedIcon:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  modificationDate 
//---------------------------------------------------------- 

- (BOOL)modificationDate_initialized:(NSDate**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_modificationDate_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedModificationDate];
		}
	}
	
	return result;
}

- (void)setModificationDate:(NSDate*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_modificationDate_initialized)
		{
			mv_flags.mv_modificationDate_initialized = YES;
			[self setCachedModificationDate:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  creationDate 
//---------------------------------------------------------- 

- (BOOL)creationDate_initialized:(NSDate**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_creationDate_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedCreationDate];
		}
	}
	
	return result;
}

- (void)setCreationDate:(NSDate*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_creationDate_initialized)
		{
			mv_flags.mv_creationDate_initialized = YES;
			[self setCachedCreationDate:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  lastUsedDate 
//---------------------------------------------------------- 

- (BOOL)lastUsedDate_initialized:(NSDate**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_lastUsedDate_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedLastUsedDate];
		}
	}
	
	return result;
}

- (void)setLastUsedDate:(NSDate*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_lastUsedDate_initialized)
		{
			mv_flags.mv_lastUsedDate_initialized = YES;
			[self setCachedLastUsedDate:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  attributeDate 
//---------------------------------------------------------- 

- (BOOL)attributeDate_initialized:(NSDate**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_attributeDate_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedAttributeDate];
		}
	}
	
	return result;
}

- (void)setAttributeDate:(NSDate*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_attributeDate_initialized)
		{
			mv_flags.mv_attributeDate_initialized = YES;
			[self setCachedAttributeDate:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  accessDate 
//---------------------------------------------------------- 

- (BOOL)accessDate_initialized:(NSDate**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_accessDate_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedAccessDate];
		}
	}
	
	return result;
}

- (void)setAccessDate:(NSDate*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_accessDate_initialized)
		{
			mv_flags.mv_accessDate_initialized = YES;
			[self setCachedAccessDate:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  version 
//---------------------------------------------------------- 

- (BOOL)version_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_version_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedVersion];
		}
	}
	
	return result;
}

- (void)setVersion:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_version_initialized)
		{
			mv_flags.mv_version_initialized = YES;
			[self setCachedVersion:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  bundleVersion 
//---------------------------------------------------------- 

- (BOOL)bundleVersion_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_bundleVersion_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedBundleVersion];
		}
	}
	
	return result;
}

- (void)setBundleVersion:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_bundleVersion_initialized)
		{
			mv_flags.mv_bundleVersion_initialized = YES;
			[self setCachedBundleVersion:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  getInfo 
//---------------------------------------------------------- 

- (BOOL)getInfo_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_getInfo_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedGetInfo];
		}
	}
	
	return result;
}

- (void)setGetInfo:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_getInfo_initialized)
		{
			mv_flags.mv_getInfo_initialized = YES;
			[self setCachedGetInfo:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  application 
//---------------------------------------------------------- 

- (BOOL)application_initialized:(NTFileDesc**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_application_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedApplication];
		}
	}
	
	return result;
}

- (void)setApplication:(NTFileDesc*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_application_initialized)
		{
			mv_flags.mv_application_initialized = YES;
			[self setCachedApplication:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  comments 
//---------------------------------------------------------- 

- (BOOL)comments_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_comments_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedComments];
		}
	}
	
	return result;
}

- (void)setComments:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_comments_initialized)
		{
			mv_flags.mv_comments_initialized = YES;
			[self setCachedComments:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  dictionaryKey 
//---------------------------------------------------------- 

- (BOOL)dictionaryKey_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_dictionaryKey_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedDictionaryKey];
		}
	}
	
	return result;
}

- (void)setDictionaryKey:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_dictionaryKey_initialized)
		{
			mv_flags.mv_dictionaryKey_initialized = YES;
			[self setCachedDictionaryKey:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  strictDictionaryKey 
//---------------------------------------------------------- 

- (BOOL)strictDictionaryKey_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_strictDictionaryKey_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedStrictDictionaryKey];
		}
	}
	
	return result;
}

- (void)setStrictDictionaryKey:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_strictDictionaryKey_initialized)
		{
			mv_flags.mv_strictDictionaryKey_initialized = YES;
			[self setCachedStrictDictionaryKey:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  permissionString 
//---------------------------------------------------------- 

- (BOOL)permissionString_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_permissionString_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedPermissionString];
		}
	}
	
	return result;
}

- (void)setPermissionString:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_permissionString_initialized)
		{
			mv_flags.mv_permissionString_initialized = YES;
			[self setCachedPermissionString:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  ownerName 
//---------------------------------------------------------- 

- (BOOL)ownerName_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_ownerName_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedOwnerName];
		}
	}
	
	return result;
}

- (void)setOwnerName:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_ownerName_initialized)
		{
			mv_flags.mv_ownerName_initialized = YES;
			[self setCachedOwnerName:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  groupName 
//---------------------------------------------------------- 

- (BOOL)groupName_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_groupName_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedGroupName];
		}
	}
	
	return result;
}

- (void)setGroupName:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_groupName_initialized)
		{
			mv_flags.mv_groupName_initialized = YES;
			[self setCachedGroupName:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  uniformTypeID 
//---------------------------------------------------------- 

- (BOOL)uniformTypeID_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_uniformTypeID_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedUniformTypeID];
		}
	}
	
	return result;
}

- (void)setUniformTypeID:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_uniformTypeID_initialized)
		{
			mv_flags.mv_uniformTypeID_initialized = YES;
			[self setCachedUniformTypeID:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  bundleSignature 
//---------------------------------------------------------- 

- (BOOL)bundleSignature_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_bundleSignature_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedBundleSignature];
		}
	}
	
	return result;
}

- (void)setBundleSignature:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_bundleSignature_initialized)
		{
			mv_flags.mv_bundleSignature_initialized = YES;
			[self setCachedBundleSignature:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  bundleIdentifier
//---------------------------------------------------------- 

- (BOOL)bundleIdentifier_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_bundleIdentifier_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedBundleIdentifier];
		}
	}
	
	return result;
}

- (void)setBundleIdentifier:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_bundleIdentifier_initialized)
		{
			mv_flags.mv_bundleIdentifier_initialized = YES;
			[self setCachedBundleIdentifier:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  itemInfo 
//---------------------------------------------------------- 

- (BOOL)itemInfo_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_itemInfo_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedItemInfo];
		}
	}
	
	return result;
}

- (void)setItemInfo:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_itemInfo_initialized)
		{
			mv_flags.mv_itemInfo_initialized = YES;
			[self setCachedItemInfo:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  volume 
//---------------------------------------------------------- 

- (BOOL)volume_initialized:(NTVolume**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_volume_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedVolume];
		}
	}
	
	return result;
}

- (void)setVolume:(NTVolume*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_volume_initialized)
		{
			mv_flags.mv_volume_initialized = YES;
			[self setCachedVolume:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  typeIdentifier 
//---------------------------------------------------------- 

- (BOOL)typeIdentifier_initialized:(NTFileTypeIdentifier**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_typeIdentifier_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedTypeIdentifier];
		}
	}
	
	return result;
}

- (void)setTypeIdentifier:(NTFileTypeIdentifier*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_typeIdentifier_initialized)
		{
			mv_flags.mv_typeIdentifier_initialized = YES;
			[self setCachedTypeIdentifier:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  isPackage
//---------------------------------------------------------- 

- (BOOL)isPackage_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isPackage_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsPackage];
		}
	}
	
	return result;	
}

- (void)setIsPackage:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isPackage_initialized)
		{
			mv_flags.mv_isPackage_initialized = YES;
			[self setCachedIsPackage:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isApplication
//---------------------------------------------------------- 

- (BOOL)isApplication_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isApplication_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsApplication];
		}
	}
	
	return result;	
}

- (void)setIsApplication:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isApplication_initialized)
		{
			mv_flags.mv_isApplication_initialized = YES;
			[self setCachedIsApplication:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isCarbonAlias
//---------------------------------------------------------- 

- (BOOL)isCarbonAlias_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isCarbonAlias_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsCarbonAlias];
		}
	}
	
	return result;	
}

- (void)setIsCarbonAlias:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isCarbonAlias_initialized)
		{
			mv_flags.mv_isCarbonAlias_initialized = YES;
			[self setCachedIsCarbonAlias:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isPathFinderAlias
//---------------------------------------------------------- 

- (BOOL)isPathFinderAlias_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isPathFinderAlias_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsPathFinderAlias];
		}
	}
	
	return result;	
}

- (void)setIsPathFinderAlias:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isPathFinderAlias_initialized)
		{
			mv_flags.mv_isPathFinderAlias_initialized = YES;
			[self setCachedIsPathFinderAlias:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isSymbolicLink
//---------------------------------------------------------- 

- (BOOL)isSymbolicLink_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isSymbolicLink_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsSymbolicLink];
		}
	}
	
	return result;	
}

- (void)setIsSymbolicLink:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isSymbolicLink_initialized)
		{
			mv_flags.mv_isSymbolicLink_initialized = YES;
			[self setCachedIsSymbolicLink:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isInvisible
//---------------------------------------------------------- 

- (BOOL)isInvisible_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isInvisible_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsInvisible];
		}
	}
	
	return result;	
}

- (void)setIsInvisible:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isInvisible_initialized)
		{
			mv_flags.mv_isInvisible_initialized = YES;
			[self setCachedIsInvisible:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isExtensionHidden
//---------------------------------------------------------- 

- (BOOL)isExtensionHidden_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isExtensionHidden_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsExtensionHidden];
		}
	}
	
	return result;	
}

- (void)setIsExtensionHidden:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isExtensionHidden_initialized)
		{
			mv_flags.mv_isExtensionHidden_initialized = YES;
			[self setCachedIsExtensionHidden:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isLocked
//---------------------------------------------------------- 

- (BOOL)isLocked_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isLocked_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsLocked];
		}
	}
	
	return result;	
}

- (void)setIsLocked:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isLocked_initialized)
		{
			mv_flags.mv_isLocked_initialized = YES;
			[self setCachedIsLocked:value];
		}
	}	
}

//---------------------------------------------------------- 
//  hasCustomIcon
//---------------------------------------------------------- 

- (BOOL)hasCustomIcon_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_hasCustomIcon_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedHasCustomIcon];
		}
	}
	
	return result;	
}

- (void)setHasCustomIcon:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_hasCustomIcon_initialized)
		{
			mv_flags.mv_hasCustomIcon_initialized = YES;
			[self setCachedHasCustomIcon:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isStationery
//---------------------------------------------------------- 

- (BOOL)isStationery_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isStationery_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsStationery];
		}
	}
	
	return result;	
}

- (void)setIsStationery:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isStationery_initialized)
		{
			mv_flags.mv_isStationery_initialized = YES;
			[self setCachedIsStationery:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isBundleBitSet
//---------------------------------------------------------- 

- (BOOL)isBundleBitSet_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isBundleBitSet_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsBundleBitSet];
		}
	}
	
	return result;	
}

- (void)setIsBundleBitSet:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isBundleBitSet_initialized)
		{
			mv_flags.mv_isBundleBitSet_initialized = YES;
			[self setCachedIsBundleBitSet:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isAliasBitSet
//---------------------------------------------------------- 

- (BOOL)isAliasBitSet_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isAliasBitSet_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsAliasBitSet];
		}
	}
	
	return result;	
}

- (void)setIsAliasBitSet:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isAliasBitSet_initialized)
		{
			mv_flags.mv_isAliasBitSet_initialized = YES;
			[self setCachedIsAliasBitSet:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isReadable
//---------------------------------------------------------- 

- (BOOL)isReadable_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isReadable_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsReadable];
		}
	}
	
	return result;	
}

- (void)setIsReadable:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isReadable_initialized)
		{
			mv_flags.mv_isReadable_initialized = YES;
			[self setCachedIsReadable:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isWritable
//---------------------------------------------------------- 

- (BOOL)isWritable_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isWritable_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsWritable];
		}
	}
	
	return result;	
}

- (void)setIsWritable:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isWritable_initialized)
		{
			mv_flags.mv_isWritable_initialized = YES;
			[self setCachedIsWritable:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isExecutable
//---------------------------------------------------------- 

- (BOOL)isExecutable_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isExecutable_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsExecutable];
		}
	}
	
	return result;	
}

- (void)setIsExecutable:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isExecutable_initialized)
		{
			mv_flags.mv_isExecutable_initialized = YES;
			[self setCachedIsExecutable:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isDeletable
//---------------------------------------------------------- 

- (BOOL)isDeletable_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isDeletable_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsDeletable];
		}
	}
	
	return result;	
}

- (void)setIsDeletable:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isDeletable_initialized)
		{
			mv_flags.mv_isDeletable_initialized = YES;
			[self setCachedIsDeletable:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isRenamable
//---------------------------------------------------------- 

- (BOOL)isRenamable_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isRenamable_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsRenamable];
		}
	}
	
	return result;	
}

- (void)setIsRenamable:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isRenamable_initialized)
		{
			mv_flags.mv_isRenamable_initialized = YES;
			[self setCachedIsRenamable:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isReadOnly
//---------------------------------------------------------- 

- (BOOL)isReadOnly_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isReadOnly_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsReadOnly];
		}
	}
	
	return result;	
}

- (void)setIsReadOnly:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isReadOnly_initialized)
		{
			mv_flags.mv_isReadOnly_initialized = YES;
			[self setCachedIsReadOnly:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isMovable
//---------------------------------------------------------- 

- (BOOL)isMovable_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isMovable_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsMovable];
		}
	}
	
	return result;	
}

- (void)setIsMovable:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isMovable_initialized)
		{
			mv_flags.mv_isMovable_initialized = YES;
			[self setCachedIsMovable:value];
		}
	}	
}

//---------------------------------------------------------- 
//  posixPermissions
//---------------------------------------------------------- 

- (BOOL)posixPermissions_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_posixPermissions_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedPosixPermissions];
		}
	}
	
	return result;	
}

- (void)setPosixPermissions:(UInt32)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_posixPermissions_initialized)
		{
			mv_flags.mv_posixPermissions_initialized = YES;
			[self setCachedPosixPermissions:value];
		}
	}	
}

//---------------------------------------------------------- 
//  posixFileMode
//---------------------------------------------------------- 

- (BOOL)posixFileMode_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_posixFileMode_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedPosixFileMode];
		}
	}
	
	return result;	
}

- (void)setPosixFileMode:(UInt32)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_posixFileMode_initialized)
		{
			mv_flags.mv_posixFileMode_initialized = YES;
			[self setCachedPosixFileMode:value];
		}
	}	
}

//---------------------------------------------------------- 
//  vRefNum
//---------------------------------------------------------- 

- (BOOL)vRefNum_initialized:(FSVolumeRefNum*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_vRefNum_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedVRefNum];
		}
	}
	
	return result;	
}

- (void)setVRefNum:(FSVolumeRefNum)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_vRefNum_initialized)
		{
			mv_flags.mv_vRefNum_initialized = YES;
			[self setCachedVRefNum:value];
		}
	}	
}

//---------------------------------------------------------- 
//  valence
//---------------------------------------------------------- 

- (BOOL)valence_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_valence_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedValence];
		}
	}
	
	return result;	
}

- (void)setValence:(UInt32)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_valence_initialized)
		{
			mv_flags.mv_valence_initialized = YES;
			[self setCachedValence:value];
		}
	}	
}

//---------------------------------------------------------- 
//  fileSize
//---------------------------------------------------------- 

- (BOOL)fileSize_initialized:(UInt64*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_fileSize_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedFileSize];
		}
	}
	
	return result;	
}

- (void)setFileSize:(UInt64)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_fileSize_initialized)
		{
			mv_flags.mv_fileSize_initialized = YES;
			[self setCachedFileSize:value];
		}
	}	
}

//---------------------------------------------------------- 
//  physicalFileSize
//---------------------------------------------------------- 

- (BOOL)physicalFileSize_initialized:(UInt64*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_physicalFileSize_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedPhysicalFileSize];
		}
	}
	
	return result;	
}

- (void)setPhysicalFileSize:(UInt64)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_physicalFileSize_initialized)
		{
			mv_flags.mv_physicalFileSize_initialized = YES;
			[self setCachedPhysicalFileSize:value];
		}
	}	
}

//---------------------------------------------------------- 
//  metadata
//---------------------------------------------------------- 

- (BOOL)metadata_initialized:(NTMetadata**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_metadata_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedMetadata];
		}
	}
	
	return result;	
}

- (void)setMetadata:(NTMetadata*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_metadata_initialized)
		{
			mv_flags.mv_metadata_initialized = YES;
			[self setCachedMetadata:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}	
}

//---------------------------------------------------------- 
//  isStickyBitSet
//---------------------------------------------------------- 

- (BOOL)isStickyBitSet_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isStickyBitSet_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsStickyBitSet];
		}
	}
	
	return result;	
}

- (void)setIsStickyBitSet:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isStickyBitSet_initialized)
		{
			mv_flags.mv_isStickyBitSet_initialized = YES;
			[self setCachedIsStickyBitSet:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isPipe
//---------------------------------------------------------- 

- (BOOL)isPipe_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isPipe_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsPipe];
		}
	}
	
	return result;	
}

- (void)setIsPipe:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isPipe_initialized)
		{
			mv_flags.mv_isPipe_initialized = YES;
			[self setCachedIsPipe:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isVolume
//---------------------------------------------------------- 

- (BOOL)isVolume_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isVolume_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsVolume];
		}
	}
	
	return result;	
}

- (void)setIsVolume:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isVolume_initialized)
		{
			mv_flags.mv_isVolume_initialized = YES;
			[self setCachedIsVolume:value];
		}
	}	
}

//---------------------------------------------------------- 
//  hasDirectoryContents
//---------------------------------------------------------- 

- (BOOL)hasDirectoryContents_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_hasDirectoryContents_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedHasDirectoryContents];
		}
	}
	
	return result;	
}

- (void)setHasDirectoryContents:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_hasDirectoryContents_initialized)
		{
			mv_flags.mv_hasDirectoryContents_initialized = YES;
			[self setCachedHasDirectoryContents:value];
		}
	}	
}

//---------------------------------------------------------- 
//  hasVisibleDirectoryContents
//---------------------------------------------------------- 

- (BOOL)hasVisibleDirectoryContents_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_hasVisibleDirectoryContents_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedHasVisibleDirectoryContents];
		}
	}
	
	return result;	
}

- (void)setHasVisibleDirectoryContents:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_hasVisibleDirectoryContents_initialized)
		{
			mv_flags.mv_hasVisibleDirectoryContents_initialized = YES;
			[self setCachedHasVisibleDirectoryContents:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isServerAlias
//---------------------------------------------------------- 

- (BOOL)isServerAlias_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isServerAlias_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsServerAlias];
		}
	}
	
	return result;	
}

- (void)setIsServerAlias:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isServerAlias_initialized)
		{
			mv_flags.mv_isServerAlias_initialized = YES;
			[self setCachedIsServerAlias:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isBrokenAlias
//---------------------------------------------------------- 

- (BOOL)isBrokenAlias_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isBrokenAlias_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsBrokenAlias];
		}
	}
	
	return result;	
}

- (void)setIsBrokenAlias:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isBrokenAlias_initialized)
		{
			mv_flags.mv_isBrokenAlias_initialized = YES;
			[self setCachedIsBrokenAlias:value];
		}
	}	
}

//---------------------------------------------------------- 
//  resolvedDesc 
//---------------------------------------------------------- 

- (BOOL)resolvedDesc_initialized:(NTFileDesc**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_resolvedDesc_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedResolvedDesc];
		}
	}
	
	return result;
}

- (void)setResolvedDesc:(NTFileDesc*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_resolvedDesc_initialized)
		{
			mv_flags.mv_resolvedDesc_initialized = YES;
			[self setCachedResolvedDesc:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

- (BOOL)rsrcForkSize_initialized:(UInt64*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_rsrcForkSize_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedRsrcForkSize];
		}
	}
	
	return result;	
}

- (void)setRsrcForkSize:(UInt64)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_rsrcForkSize_initialized)
		{
			mv_flags.mv_rsrcForkSize_initialized = YES;
			[self setCachedRsrcForkSize:value];
		}
	}	
}

- (BOOL)dataForkSize_initialized:(UInt64*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_dataForkSize_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedDataForkSize];
		}
	}
	
	return result;		
}

- (void)setDataForkSize:(UInt64)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_dataForkSize_initialized)
		{
			mv_flags.mv_dataForkSize_initialized = YES;
			[self setCachedDataForkSize:value];
		}
	}	
}

- (BOOL)rsrcForkPhysicalSize_initialized:(UInt64*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mRsrcForkPhysicalSize_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedRsrcForkPhysicalSize];
		}
	}
	
	return result;	
}

- (void)setRsrcForkPhysicalSize:(UInt64)value;
{
	@synchronized(self) {
		if (!mv_flags.mRsrcForkPhysicalSize_initialized)
		{
			mv_flags.mRsrcForkPhysicalSize_initialized = YES;
			[self setCachedRsrcForkPhysicalSize:value];
		}
	}	
}

- (BOOL)dataForkPhysicalSize_initialized:(UInt64*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mDataForkPhysicalSize_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedDataForkPhysicalSize];
		}
	}
	
	return result;		
}

- (void)setDataForkPhysicalSize:(UInt64)value;
{
	@synchronized(self) {
		if (!mv_flags.mDataForkPhysicalSize_initialized)
		{
			mv_flags.mDataForkPhysicalSize_initialized = YES;
			[self setCachedDataForkPhysicalSize:value];
		}
	}	
}

//---------------------------------------------------------- 
//  type
//---------------------------------------------------------- 

- (BOOL)type_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_type_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedType];
		}
	}
	
	return result;	
}

- (void)setType:(UInt32)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_type_initialized)
		{
			mv_flags.mv_type_initialized = YES;
			[self setCachedType:value];
		}
	}	
}

//---------------------------------------------------------- 
//  creator
//---------------------------------------------------------- 

- (BOOL)creator_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_creator_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedCreator];
		}
	}
	
	return result;	
}

- (void)setCreator:(UInt32)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_creator_initialized)
		{
			mv_flags.mv_creator_initialized = YES;
			[self setCachedCreator:value];
		}
	}	
}

//---------------------------------------------------------- 
//  label
//---------------------------------------------------------- 

- (BOOL)label_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_label_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedLabel];
		}
	}
	
	return result;	
}

- (void)setLabel:(UInt32)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_label_initialized)
		{
			mv_flags.mv_label_initialized = YES;
			[self setCachedLabel:value];
		}
	}	
}

//---------------------------------------------------------- 
//  groupID
//---------------------------------------------------------- 

- (BOOL)groupID_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_groupID_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedGroupID];
		}
	}
	
	return result;	
}

- (void)setGroupID:(UInt32)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_groupID_initialized)
		{
			mv_flags.mv_groupID_initialized = YES;
			[self setCachedGroupID:value];
		}
	}	
}

//---------------------------------------------------------- 
//  ownerID
//---------------------------------------------------------- 

- (BOOL)ownerID_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_ownerID_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedOwnerID];
		}
	}
	
	return result;	
}

- (void)setOwnerID:(UInt32)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_ownerID_initialized)
		{
			mv_flags.mv_ownerID_initialized = YES;
			[self setCachedOwnerID:value];
		}
	}	
}

//---------------------------------------------------------- 
//  nodeID
//---------------------------------------------------------- 

- (BOOL)nodeID_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_nodeID_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedNodeID];
		}
	}
	
	return result;	
}

- (void)setNodeID:(UInt32)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_nodeID_initialized)
		{
			mv_flags.mv_nodeID_initialized = YES;
			[self setCachedNodeID:value];
		}
	}	
}

//---------------------------------------------------------- 
//  parentDirID
//---------------------------------------------------------- 

- (BOOL)parentDirID_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_parentDirID_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedParentDirID];
		}
	}
	
	return result;	
}

- (void)setParentDirID:(UInt32)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_parentDirID_initialized)
		{
			mv_flags.mv_parentDirID_initialized = YES;
			[self setCachedParentDirID:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isParentAVolume
//---------------------------------------------------------- 

- (BOOL)isParentAVolume_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isParentAVolume_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsParentAVolume];
		}
	}
	
	return result;	
}

- (void)setIsParentAVolume:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isParentAVolume_initialized)
		{
			mv_flags.mv_isParentAVolume_initialized = YES;
			[self setCachedIsParentAVolume:value];
		}
	}	
}

//---------------------------------------------------------- 
//  isNameLocked
//---------------------------------------------------------- 

- (BOOL)isNameLocked_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_isNameLocked_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedIsNameLocked];
		}
	}
	
	return result;	
}

- (void)setIsNameLocked:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_isNameLocked_initialized)
		{
			mv_flags.mv_isNameLocked_initialized = YES;
			[self setCachedIsNameLocked:value];
		}
	}	
}

//---------------------------------------------------------- 
//  originalAliasFilePath 
//---------------------------------------------------------- 

- (BOOL)originalAliasFilePath_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_originalAliasFilePath_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedOriginalAliasFilePath];
		}
	}
	
	return result;
}

- (void)setOriginalAliasFilePath:(NSString*)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_originalAliasFilePath_initialized)
		{
			mv_flags.mv_originalAliasFilePath_initialized = YES;
			[self setCachedOriginalAliasFilePath:value];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  hasBeenModified
//---------------------------------------------------------- 

- (BOOL)hasBeenModified_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_hasBeenModified_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedHasBeenModified];
		}
	}
	
	return result;	
}

- (void)setHasBeenModified:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_hasBeenModified_initialized)
		{
			mv_flags.mv_hasBeenModified_initialized = YES;
			[self setCachedHasBeenModified:value];
		}
	}	
}

//---------------------------------------------------------- 
//  hasBeenRenamed
//---------------------------------------------------------- 

- (BOOL)hasBeenRenamed_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = mv_flags.mv_hasBeenRenamed_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [self cachedHasBeenRenamed];
		}
	}
	
	return result;	
}

- (void)setHasBeenRenamed:(BOOL)value;
{
	@synchronized(self) {
		if (!mv_flags.mv_hasBeenRenamed_initialized)
		{
			mv_flags.mv_hasBeenRenamed_initialized = YES;
			[self setCachedHasBeenRenamed:value];
		}
	}	
}

@end
