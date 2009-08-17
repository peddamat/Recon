//
//  NTFileDescData.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/24/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTVolume, NTFileTypeIdentifier;

@interface NTFileDescData : NSObject{
	
    NSString* cachedDisplayName;
	
	NSString* cachedKind;
	NSString* cachedArchitecture;
    NSString* cachedExtension;
	NTIcon* cachedIcon;
	
	NSDate* cachedModificationDate;
    NSDate* cachedAttributeDate;
    NSDate* cachedAccessDate;
    NSDate* cachedLastUsedDate;
    NSDate* cachedCreationDate;
	
	NSString* cachedVersion;
	NSString* cachedBundleVersion;
	NSString* cachedGetInfo;
	NTFileDesc* cachedApplication;
	NSString* cachedComments;
	NSString* cachedDictionaryKey;
	NSString* cachedStrictDictionaryKey;
	
	NSString* cachedPermissionString;
    NSString* cachedOwnerName;
    NSString* cachedGroupName;
	NSString* cachedUniformTypeID;
	NSString* cachedBundleSignature;
	NSString* cachedBundleIdentifier;
	NSString* cachedItemInfo;

	NTVolume* cachedVolume;
	NTFileTypeIdentifier* cachedTypeIdentifier;
	
    UInt32 cachedPosixPermissions;
    UInt32 cachedPosixFileMode;

    FSVolumeRefNum cachedVRefNum;
	
    // folder size and valence
    UInt32 cachedValence;  // returns -1 if not supported
    
    UInt64 cachedFileSize;
    UInt64 cachedPhysicalFileSize;
	
	UInt64 cachedRsrcForkSize;
	UInt64 cachedDataForkSize;

	UInt64 cachedRsrcForkPhysicalSize;
	UInt64 cachedDataForkPhysicalSize;
	
	NTMetadata *cachedMetadata;	
	
	NTFileDesc* cachedResolvedDesc;
	
	UInt32 cachedType;
	UInt32 cachedCreator;
	UInt32 cachedLabel;
	UInt32 cachedGroupID;
	UInt32 cachedOwnerID;

	UInt32 cachedNodeID;
	UInt32 cachedParentDirID;
	
	NSString* cachedOriginalAliasFilePath; 
	
	struct {
        unsigned int mv_cachedIsFile:1;
		
		unsigned int mv_cachedIsApplication:1;
		unsigned int mv_cachedIsPackage:1;
		unsigned int mv_cachedIsCarbonAlias:1;
		unsigned int mv_cachedIsPathFinderAlias:1;
        unsigned int mv_cachedIsSymbolicLink:1;
		
		unsigned int mv_cachedIsInvisible:1;        
		unsigned int mv_cachedIsExtensionHidden:1;
        unsigned int mv_cachedIsLocked:1;
        unsigned int mv_cachedHasCustomIcon:1;
        unsigned int mv_cachedIsStationery:1;
        unsigned int mv_cachedIsBundleBitSet:1;
        unsigned int mv_cachedIsAliasBitSet:1;
        unsigned int mv_cachedIsReadable:1;
        unsigned int mv_cachedIsExecutable:1;
        unsigned int mv_cachedIsWritable:1;
        unsigned int mv_cachedIsDeletable:1;
        unsigned int mv_cachedIsRenamable:1;
        unsigned int mv_cachedIsReadOnly:1;
        unsigned int mv_cachedIsMovable:1;
						
		unsigned int mv_cachedIsStickyBitSet:1;
		unsigned int mv_cachedIsPipe:1;
        unsigned int mv_cachedIsVolume:1;
        unsigned int mv_cachedHasDirectoryContents:1;
        unsigned int mv_cachedHasVisibleDirectoryContents:1;
		unsigned int mv_cachedIsServerAlias:1;
        unsigned int mv_cachedIsBrokenAlias:1;
				
		unsigned int mv_cachedIsParentAVolume:1;
        unsigned int mv_cachedIsNameLocked:1;
        unsigned int mv_cachedHasBeenModified:1;
        unsigned int mv_cachedHasBeenRenamed:1;
		
    } mv_bools;    
	
	struct {
        unsigned int mv_displayName_initialized:1;
        unsigned int mv_isFile_initialized:1;
		
        unsigned int mv_kind_initialized:1;
        unsigned int mv_architecture_initialized:1;
        unsigned int mv_extension_initialized:1;
        unsigned int mv_icon_initialized:1;
		
		unsigned int mv_modificationDate_initialized:1;
		unsigned int mv_creationDate_initialized:1;
		unsigned int mv_attributeDate_initialized:1;
		unsigned int mv_accessDate_initialized:1;
		unsigned int mv_lastUsedDate_initialized:1;
		
		unsigned int mv_version_initialized:1;
		unsigned int mv_bundleVersion_initialized:1;
		unsigned int mv_getInfo_initialized:1;
		unsigned int mv_application_initialized:1;
		unsigned int mv_comments_initialized:1;
		unsigned int mv_dictionaryKey_initialized:1;		
		unsigned int mv_strictDictionaryKey_initialized:1;		
		
		unsigned int mv_permissionString_initialized:1;		
		unsigned int mv_ownerName_initialized:1;		
		unsigned int mv_groupName_initialized:1;		
		unsigned int mv_uniformTypeID_initialized:1;		
		unsigned int mv_bundleSignature_initialized:1;		
		unsigned int mv_bundleIdentifier_initialized:1;		
		unsigned int mv_itemInfo_initialized:1;		
		
		unsigned int mv_volume_initialized:1;		
		unsigned int mv_typeIdentifier_initialized:1;		
		
		unsigned int mv_isPackage_initialized:1;
		unsigned int mv_isApplication_initialized:1;
		unsigned int mv_isCarbonAlias_initialized:1;
        unsigned int mv_isPathFinderAlias_initialized:1;
        unsigned int mv_isSymbolicLink_initialized:1;		
		
		unsigned int mv_isInvisible_initialized:1;
        unsigned int mv_isExtensionHidden_initialized:1;
        unsigned int mv_isLocked_initialized:1;
        unsigned int mv_hasCustomIcon_initialized:1;
        unsigned int mv_isStationery_initialized:1;
        unsigned int mv_isBundleBitSet_initialized:1;
        unsigned int mv_isAliasBitSet_initialized:1;
        unsigned int mv_isReadable_initialized:1;
        unsigned int mv_isExecutable_initialized:1;
        unsigned int mv_isWritable_initialized:1;
        unsigned int mv_isDeletable_initialized:1;
        unsigned int mv_isRenamable_initialized:1;
        unsigned int mv_isReadOnly_initialized:1;
        unsigned int mv_isMovable_initialized:1;
	
		unsigned int mv_posixPermissions_initialized:1;
		unsigned int mv_posixFileMode_initialized:1;
		unsigned int mv_vRefNum_initialized:1;
		unsigned int mv_valence_initialized:1;
		unsigned int mv_fileSize_initialized:1;
		unsigned int mv_physicalFileSize_initialized:1;
		unsigned int mv_metadata_initialized:1;
		
		unsigned int mv_isStickyBitSet_initialized:1;
		unsigned int mv_isPipe_initialized:1;
        unsigned int mv_isVolume_initialized:1;
        unsigned int mv_hasDirectoryContents_initialized:1;
        unsigned int mv_hasVisibleDirectoryContents_initialized:1;
        unsigned int mv_isServerAlias_initialized:1;
        unsigned int mv_isBrokenAlias_initialized:1;
				
		unsigned int mv_resolvedDesc_initialized:1;
		
		unsigned int mv_rsrcForkSize_initialized:1;
		unsigned int mv_dataForkSize_initialized:1;

		unsigned int mRsrcForkPhysicalSize_initialized:1;
		unsigned int mDataForkPhysicalSize_initialized:1;

		unsigned int mv_type_initialized:1;
		unsigned int mv_creator_initialized:1;
		unsigned int mv_label_initialized:1;
		unsigned int mv_groupID_initialized:1;
		unsigned int mv_ownerID_initialized:1;
		
		unsigned int mv_nodeID_initialized:1;
		unsigned int mv_parentDirID_initialized:1;

		unsigned int mv_isParentAVolume_initialized:1;
        unsigned int mv_isNameLocked_initialized:1;
		
		unsigned int mv_originalAliasFilePath_initialized:1;
        unsigned int mv_hasBeenModified_initialized:1;
        unsigned int mv_hasBeenRenamed_initialized:1;

	} mv_flags;    
}

+ (NTFileDescData *)cache;

- (BOOL)displayName_initialized:(NSString**)outValue;
- (void)setDisplayName:(NSString*)value;

- (BOOL)isFile_initialized:(BOOL*)outValue;
- (void)setIsFile:(BOOL)value;

- (BOOL)kind_initialized:(NSString**)outValue;
- (void)setKind:(NSString*)value;

- (BOOL)architecture_initialized:(NSString**)outValue;
- (void)setArchitecture:(NSString*)value;

- (BOOL)extension_initialized:(NSString**)outValue;
- (void)setExtension:(NSString*)value;

- (BOOL)icon_initialized:(NTIcon**)outValue;
- (void)setIcon:(NTIcon*)value;

- (BOOL)modificationDate_initialized:(NSDate**)outValue;
- (void)setModificationDate:(NSDate*)value;

- (BOOL)attributeDate_initialized:(NSDate**)outValue;
- (void)setAttributeDate:(NSDate*)value;

- (BOOL)accessDate_initialized:(NSDate**)outValue;
- (void)setAccessDate:(NSDate*)value;

- (BOOL)creationDate_initialized:(NSDate**)outValue;
- (void)setCreationDate:(NSDate*)value;

- (BOOL)lastUsedDate_initialized:(NSDate**)outValue;
- (void)setLastUsedDate:(NSDate*)value;

- (BOOL)version_initialized:(NSString**)outValue;
- (void)setVersion:(NSString*)value;

- (BOOL)bundleVersion_initialized:(NSString**)outValue;
- (void)setBundleVersion:(NSString*)value;

- (BOOL)bundleIdentifier_initialized:(NSString**)outValue;
- (void)setBundleIdentifier:(NSString*)value;

- (BOOL)getInfo_initialized:(NSString**)outValue;
- (void)setGetInfo:(NSString*)value;

- (BOOL)application_initialized:(NTFileDesc**)outValue;
- (void)setApplication:(NTFileDesc*)value;

- (BOOL)comments_initialized:(NSString**)outValue;
- (void)setComments:(NSString*)value;

- (BOOL)dictionaryKey_initialized:(NSString**)outValue;
- (void)setDictionaryKey:(NSString*)value;

- (BOOL)strictDictionaryKey_initialized:(NSString**)outValue;
- (void)setStrictDictionaryKey:(NSString*)value;

- (BOOL)permissionString_initialized:(NSString**)outValue;
- (void)setPermissionString:(NSString*)value;

- (BOOL)ownerName_initialized:(NSString**)outValue;
- (void)setOwnerName:(NSString*)value;

- (BOOL)groupName_initialized:(NSString**)outValue;
- (void)setGroupName:(NSString*)value;

- (BOOL)uniformTypeID_initialized:(NSString**)outValue;
- (void)setUniformTypeID:(NSString*)value;

- (BOOL)bundleSignature_initialized:(NSString**)outValue;
- (void)setBundleSignature:(NSString*)value;

- (BOOL)itemInfo_initialized:(NSString**)outValue;
- (void)setItemInfo:(NSString*)value;

- (BOOL)volume_initialized:(NTVolume**)outValue;
- (void)setVolume:(NTVolume*)value;

- (BOOL)typeIdentifier_initialized:(NTFileTypeIdentifier**)outValue;
- (void)setTypeIdentifier:(NTFileTypeIdentifier*)value;

- (BOOL)isPackage_initialized:(BOOL*)outValue;
- (void)setIsPackage:(BOOL)value;

- (BOOL)isApplication_initialized:(BOOL*)outValue;
- (void)setIsApplication:(BOOL)value;

- (BOOL)isCarbonAlias_initialized:(BOOL*)outValue;
- (void)setIsCarbonAlias:(BOOL)value;

- (BOOL)isPathFinderAlias_initialized:(BOOL*)outValue;
- (void)setIsPathFinderAlias:(BOOL)value;

- (BOOL)isSymbolicLink_initialized:(BOOL*)outValue;
- (void)setIsSymbolicLink:(BOOL)value;

- (BOOL)isInvisible_initialized:(BOOL*)outValue;
- (void)setIsInvisible:(BOOL)value;

- (BOOL)isExtensionHidden_initialized:(BOOL*)outValue;
- (void)setIsExtensionHidden:(BOOL)value;

- (BOOL)isLocked_initialized:(BOOL*)outValue;
- (void)setIsLocked:(BOOL)value;

- (BOOL)hasCustomIcon_initialized:(BOOL*)outValue;
- (void)setHasCustomIcon:(BOOL)value;

- (BOOL)isStationery_initialized:(BOOL*)outValue;
- (void)setIsStationery:(BOOL)value;

- (BOOL)isBundleBitSet_initialized:(BOOL*)outValue;
- (void)setIsBundleBitSet:(BOOL)value;

- (BOOL)isAliasBitSet_initialized:(BOOL*)outValue;
- (void)setIsAliasBitSet:(BOOL)value;

- (BOOL)isReadable_initialized:(BOOL*)outValue;
- (void)setIsReadable:(BOOL)value;

- (BOOL)isWritable_initialized:(BOOL*)outValue;
- (void)setIsWritable:(BOOL)value;

- (BOOL)isExecutable_initialized:(BOOL*)outValue;
- (void)setIsExecutable:(BOOL)value;

- (BOOL)isDeletable_initialized:(BOOL*)outValue;
- (void)setIsDeletable:(BOOL)value;

- (BOOL)isRenamable_initialized:(BOOL*)outValue;
- (void)setIsRenamable:(BOOL)value;

- (BOOL)isReadOnly_initialized:(BOOL*)outValue;
- (void)setIsReadOnly:(BOOL)value;

- (BOOL)isMovable_initialized:(BOOL*)outValue;
- (void)setIsMovable:(BOOL)value;

- (BOOL)posixPermissions_initialized:(UInt32*)outValue;
- (void)setPosixPermissions:(UInt32)value;

- (BOOL)posixFileMode_initialized:(UInt32*)outValue;
- (void)setPosixFileMode:(UInt32)value;

- (BOOL)vRefNum_initialized:(FSVolumeRefNum*)outValue;
- (void)setVRefNum:(FSVolumeRefNum)value;

- (BOOL)valence_initialized:(UInt32*)outValue;
- (void)setValence:(UInt32)value;

- (BOOL)fileSize_initialized:(UInt64*)outValue;
- (void)setFileSize:(UInt64)value;

- (BOOL)physicalFileSize_initialized:(UInt64*)outValue;
- (void)setPhysicalFileSize:(UInt64)value;

- (BOOL)metadata_initialized:(NTMetadata**)outValue;
- (void)setMetadata:(NTMetadata*)value;

- (BOOL)isStickyBitSet_initialized:(BOOL*)outValue;
- (void)setIsStickyBitSet:(BOOL)value;

- (BOOL)isPipe_initialized:(BOOL*)outValue;
- (void)setIsPipe:(BOOL)value;

- (BOOL)isVolume_initialized:(BOOL*)outValue;
- (void)setIsVolume:(BOOL)value;

- (BOOL)hasDirectoryContents_initialized:(BOOL*)outValue;
- (void)setHasDirectoryContents:(BOOL)value;

- (BOOL)hasVisibleDirectoryContents_initialized:(BOOL*)outValue;
- (void)setHasVisibleDirectoryContents:(BOOL)value;

- (BOOL)isServerAlias_initialized:(BOOL*)outValue;
- (void)setIsServerAlias:(BOOL)value;

- (BOOL)isBrokenAlias_initialized:(BOOL*)outValue;
- (void)setIsBrokenAlias:(BOOL)value;

- (BOOL)resolvedDesc_initialized:(NTFileDesc**)outValue;
- (void)setResolvedDesc:(NTFileDesc*)value;

- (BOOL)rsrcForkSize_initialized:(UInt64*)outValue;
- (void)setRsrcForkSize:(UInt64)value;

- (BOOL)dataForkSize_initialized:(UInt64*)outValue;
- (void)setDataForkSize:(UInt64)value;

- (BOOL)rsrcForkPhysicalSize_initialized:(UInt64*)outValue;
- (void)setRsrcForkPhysicalSize:(UInt64)value;

- (BOOL)dataForkPhysicalSize_initialized:(UInt64*)outValue;
- (void)setDataForkPhysicalSize:(UInt64)value;

- (BOOL)type_initialized:(UInt32*)outValue;
- (void)setType:(UInt32)value;

- (BOOL)creator_initialized:(UInt32*)outValue;
- (void)setCreator:(UInt32)value;

- (BOOL)label_initialized:(UInt32*)outValue;
- (void)setLabel:(UInt32)value;

- (BOOL)groupID_initialized:(UInt32*)outValue;
- (void)setGroupID:(UInt32)value;

- (BOOL)ownerID_initialized:(UInt32*)outValue;
- (void)setOwnerID:(UInt32)value;

- (BOOL)nodeID_initialized:(UInt32*)outValue;
- (void)setNodeID:(UInt32)value;

- (BOOL)parentDirID_initialized:(UInt32*)outValue;
- (void)setParentDirID:(UInt32)value;

- (BOOL)isParentAVolume_initialized:(BOOL*)outValue;
- (void)setIsParentAVolume:(BOOL)value;

- (BOOL)isNameLocked_initialized:(BOOL*)outValue;
- (void)setIsNameLocked:(BOOL)value;

- (BOOL)originalAliasFilePath_initialized:(NSString**)outValue;
- (void)setOriginalAliasFilePath:(NSString*)value;

- (BOOL)hasBeenModified_initialized:(BOOL*)outValue;
- (void)setHasBeenModified:(BOOL)value;

- (BOOL)hasBeenRenamed_initialized:(BOOL*)outValue;
- (void)setHasBeenRenamed:(BOOL)value;

@end

