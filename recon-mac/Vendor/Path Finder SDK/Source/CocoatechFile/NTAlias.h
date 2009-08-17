//
//  NTAlias.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Fri Jun 13 2003.
//  Copyright (c) 2003 CocoaTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NTFileDesc;

@interface NTAlias : NSObject <NSCoding>
{
    NTFileDesc* _desc;
    NSData* _alias;
    AliasHandle _aliasHandle;

    BOOL _gotAliasInfo;
    FSAliasInfoBitmap _whichAliasInfo;
    FSAliasInfo _aliasInfo;
    NSString* _path;
    NSString* _targetName;
    NSString* _volumeName;

    BOOL _aliasRequiresUIToResolve;
    
    OSType _userType;
    unsigned short _aliasSize;

    // we record the type of the alias so we can identify the type if we have trouble resolving it in the future (so we can give it the right icon etc)
    OSType _aliasType;
}

+ (NTAlias*)aliasWithAliasFile:(NTFileDesc*)desc; // this extracts the 'alis' resource from an alias file
+ (NTAlias*)aliasWithDesc:(NTFileDesc*)desc;  // this creates an aliasHandle for this file
+ (NTAlias*)aliasWithAlias:(NSData*)alias;  // takes an aliasHandle
- (NTAlias*)newAlias;

- (NTFileDesc*)desc;
- (NTFileDesc*)desc:(BOOL)resolveCompletely;  // call this to resolve all aliases (remote servers that may ask for password)

// displayName returns the descs displayName, or the targetName if it can't be resolved
- (NSString*)displayName;
- (NSString*)displayPath;

    // kContainerServerAliasType, kContainerHardDiskAliasType, etc
- (OSType)aliasType;

- (BOOL)aliasRequiresUIToResolve;

- (NSData*)alias;

- (FSAliasInfo*)aliasInfo;
- (FSAliasInfoBitmap)whichAliasInfo;

// FSAliasInfo easy accessors
- (NSString*)path;
- (NSString*)targetName;
- (NSString*)volumeName;

- (NSDate*)volumeCreationDate;
- (NSDate*)targetCreationDate;
- (OSType)fileType;
- (OSType)fileCreator;
- (UInt32)parentDirID;
- (UInt32)nodeID;
- (UInt16)filesystemID;
- (UInt16)signature;
- (BOOL)volumeIsBootVolume;
- (BOOL)volumeIsAutomounted;
- (BOOL)volumeIsEjectable;
- (BOOL)volumeHasPersistentFileIDs;
- (BOOL)isDirectory;

- (OSType)userType;

@end

@interface NTAlias (Utilities)
+ (NTFileDesc*)resolveAlias:(AliasHandle)aliasHandle resolveIfRequiresUI:(BOOL)resolveIfRequiresUI outAliasRequiresUIToResolve:(BOOL*)outAliasRequiresUIToResolve outWasChanged:(BOOL*)outWasChanged;

+ (NTFileDesc*)resolveAliasFile:(NTFileDesc*)aliasFile 
			resolveIfRequiresUI:(BOOL)resolveIfRequiresUI 
	outAliasRequiresUIToResolve:(BOOL*)outAliasRequiresUIToResolve;

+ (AliasHandle)aliasHandleForDesc:(NTFileDesc*)fileDesc;
+ (NSData*)aliasResourceFromAliasFile:(NTFileDesc*)aliasFile dataFork:(BOOL)dataFork;

    // kContainerServerAliasType, kContainerHardDiskAliasType, etc
+ (OSType)fileTypeForAliasFileOfDesc:(NTFileDesc*)desc;
@end
