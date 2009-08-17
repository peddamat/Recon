//
//  NTAlias.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Fri Jun 13 2003.
//  Copyright (c) 2003 CocoaTech. All rights reserved.
//

#import "NTAlias.h"
#import "NTAliasFileManager.h"
#import "NTVolume.h"
#import "NTResourceMgr.h"

@interface NTAlias (Private)
- (void)initAlias;
- (void)initDesc:(BOOL)resolveIfRequiresUI;
- (AliasHandle)aliasHandle;
- (void)setAlias:(NSData*)aliasData;
@end

// =============================================================================

@implementation NTAlias

- (void)commonInit;
{    
    [self initAlias];
    [self initDesc:NO];
}

- (id)initWithAlias:(NSData*)alias;
{
    self = [super init];

    [self setAlias:alias];
    [self commonInit];

    return self;
}

- (id)initWithAliasFile:(NTFileDesc*)desc;
{
    if ([desc isCarbonAlias])
    {
		NSData *aliasData = [NTAlias aliasResourceFromAliasFile:desc dataFork:NO];
        if (aliasData)
        {                        
            self = [self initWithAlias:aliasData];
			
            _aliasType = [desc type];
            
            return self;
        }
    }
    
    return nil;
}

+ (NTAlias*)aliasWithDesc:(NTFileDesc*)desc;
{
	if (!desc || [desc isComputer])
		return nil;
	
    NTAlias* result = [[NTAlias alloc] init];

	result->_desc = [desc retain];
    [result commonInit];
	
    result->_aliasType = [NTAlias fileTypeForAliasFileOfDesc:desc];
	
	
    return [result autorelease];
}

+ (NTAlias*)aliasWithAlias:(NSData*)alias;
{
    NTAlias* result = [[NTAlias alloc] initWithAlias:alias];
    
    return [result autorelease];    
}

+ (NTAlias*)aliasWithAliasFile:(NTFileDesc*)desc; // this extracts the 'alis' resource from an alias file
{    
    NTAlias* result = [[NTAlias alloc] initWithAliasFile:desc];

    return [result autorelease];
}

- (NTAlias*)newAlias;
{
	return [NTAlias aliasWithAlias:[self alias]];
}

- (void)dealloc;
{
    [self setAlias:nil];
    [_desc release];

    [_path release];
    [_targetName release];
    [_volumeName release];
    
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
	if ([self alias])
	{
		[aCoder encodeObject:[self alias] forKey:@"alias"];
		[aCoder encodeObject:[NSNumber numberWithUnsignedInt:[self aliasType]] forKey:@"type"];
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder;
{
	NSData* alias = [aDecoder decodeObjectForKey:@"alias"];
	_aliasType = [[aDecoder decodeObjectForKey:@"type"] unsignedIntValue];
	
    if (alias)
    {
        self = [self initWithAlias:alias];

        return self;
    }

    return nil;
}

// displayName returns the descs displayName, or the targetName if it can't be resolved
- (NSString*)displayName;
{
	NTFileDesc* desc = [self desc];
	
	if (desc)
		return [desc displayName];
	
	return [self targetName];
}

- (NSString*)displayPath;
{
	NTFileDesc* desc = [self desc];
	
	if (desc)
		return [desc displayPath];
	
	return [self path];	
}

- (NTFileDesc*)desc;
{
    return [self desc:NO];
}

- (NTFileDesc*)desc:(BOOL)resolveCompletely;  // call this to resolve all aliases (remote servers that may ask for password)
{
    if (_desc && resolveCompletely)
    {
        // requires UI to resolve, delete the desc and resolve
        if (_aliasRequiresUIToResolve)
        {
            [_desc release];
            _desc = nil;
        }
        else // else just do a double check to see if the file is still the same
        {
            // we double check the desc if we pass resolveCompletely, resolveCompletely is set to yes when we have to be sure that the desc is good (basically anything but drawing)
            // this way we can detect if a file has been moved or a server has been unmounted
            if (![_desc stillExists] || [_desc hasBeenModified])
            {
                [_desc release];
                _desc = nil;
            }
        }
    }
    
    if (!_desc)
    {
        // resolve the alias and recreate the _desc
        [self initDesc:resolveCompletely];
    }

	NTFileDesc *result = _desc;
	
    if (resolveCompletely && [result isAlias])
        result = [result descResolveIfAlias:YES];
    
	// no use returning an invalid result, set to nil if invalid
	if (![result isValid])
		result = nil;
	
    return result;
}

- (NSData*)alias;
{
    return _alias;
}

// kContainerServerAliasType, kContainerHardDiskAliasType, etc
- (OSType)aliasType;
{
    return _aliasType;
}

- (BOOL)aliasRequiresUIToResolve;
{    
     return _aliasRequiresUIToResolve;
}

// info in the AliasRecord
- (OSType)userType;
{
    OSType userType = 0;

    if ([_alias length] >= sizeof(AliasRecord))
	{
		const AliasRecord *alias = (const AliasRecord *)[_alias bytes];

		userType = GetAliasUserTypeFromPtr(alias);
	}
	
    return userType;
}

- (NSString*)path;
{
    [self aliasInfo];

    return _path;
}

- (NSString*)targetName;
{
    [self aliasInfo];

    return _targetName;
}

- (NSString*)volumeName;
{
    [self aliasInfo];

    return _volumeName;
}

- (FSAliasInfo*)aliasInfo;
{
    if (!_gotAliasInfo)
    {
        _gotAliasInfo = YES;

        AliasHandle aliasHandle = [self aliasHandle];
        if (aliasHandle)
        {
            HFSUniStr255 volumeName, targetName;
            CFStringRef pathString;

            OSStatus err = FSCopyAliasInfo(aliasHandle, &targetName, &volumeName, &pathString, &_whichAliasInfo, &_aliasInfo);
            if (!err && (_whichAliasInfo != kFSAliasInfoNone))
            {
                _path = [(NSString*) pathString retain];
                _targetName = [[NSString fileNameWithHFSUniStr255:&targetName] retain];
                _volumeName = [[NSString fileNameWithHFSUniStr255:&volumeName] retain];

                CFRelease(pathString);
            }
        }
    }

    return &_aliasInfo;
}

- (FSAliasInfoBitmap)whichAliasInfo;
{
    [self aliasInfo];
    
    return _whichAliasInfo;
}

// FSAliasInfo easy accessors
- (NSDate*)volumeCreationDate;
{
    [self aliasInfo];

    if ((_whichAliasInfo & kFSAliasInfoVolumeCreateDate) != 0)
        return [NSDate dateFromUTCDateTime:_aliasInfo.volumeCreateDate];

    return nil;
}

- (NSDate*)targetCreationDate;
{
    [self aliasInfo];

    if ((_whichAliasInfo & kFSAliasInfoTargetCreateDate) != 0)
        return [NSDate dateFromUTCDateTime:_aliasInfo.targetCreateDate];

    return nil;
}

- (OSType)fileType;
{
    if ((_whichAliasInfo & kFSAliasInfoFinderInfo) != 0)
        return _aliasInfo.fileType;
    
    return 0;
}

- (OSType)fileCreator;
{
    [self aliasInfo];

    if ((_whichAliasInfo & kFSAliasInfoFinderInfo) != 0)
        return _aliasInfo.fileCreator;

    return 0;
}

- (UInt32)parentDirID;
{
    [self aliasInfo];

    if ((_whichAliasInfo & kFSAliasInfoIDs) != 0)
        return _aliasInfo.parentDirID;

    return 0;
}

- (UInt32)nodeID;
{
    [self aliasInfo];

    if ((_whichAliasInfo & kFSAliasInfoIDs) != 0)
        return _aliasInfo.nodeID;

    return 0;
}

- (UInt16)filesystemID;
{
    [self aliasInfo];

    if ((_whichAliasInfo & kFSAliasInfoFSInfo) != 0)
        return _aliasInfo.filesystemID;

    return 0;
}

- (UInt16)signature;
{
    [self aliasInfo];

    if ((_whichAliasInfo & kFSAliasInfoFSInfo) != 0)
        return _aliasInfo.signature;

    return 0;
}

- (BOOL)volumeIsBootVolume;
{
    [self aliasInfo];

    if ((_whichAliasInfo & kFSAliasInfoVolumeFlags) != 0)
        return _aliasInfo.volumeIsBootVolume;

    return 0;
}

- (BOOL)volumeIsAutomounted;
{
    [self aliasInfo];

    if ((_whichAliasInfo & kFSAliasInfoVolumeFlags) != 0)
        return _aliasInfo.volumeIsAutomounted;

    return 0;
}

- (BOOL)volumeIsEjectable;
{
    [self aliasInfo];

    if ((_whichAliasInfo & kFSAliasInfoVolumeFlags) != 0)
        return _aliasInfo.volumeIsEjectable;

    return 0;
}

- (BOOL)volumeHasPersistentFileIDs;
{
    [self aliasInfo];

    if ((_whichAliasInfo & kFSAliasInfoVolumeFlags) != 0)
        return _aliasInfo.volumeHasPersistentFileIDs;

    return 0;
}

- (BOOL)isDirectory;
{
    [self aliasInfo];

    if ((_whichAliasInfo & kFSAliasInfoIsDirectory) != 0)
        return _aliasInfo.isDirectory;

    return 0;
}

@end

@implementation NTAlias (Private)

- (void)initDesc:(BOOL)resolveIfRequiresUI;  // call this to resolve all aliases (remote servers that may ask for password);
{
    if (!_desc)
    {
        AliasHandle aliasHandle = [self aliasHandle];
        if (aliasHandle)
        {
            BOOL outAliasRequiresUIToResolve;
            BOOL wasChanged;

            _desc = [[NTAlias resolveAlias:aliasHandle resolveIfRequiresUI:resolveIfRequiresUI outAliasRequiresUIToResolve:&outAliasRequiresUIToResolve outWasChanged:&wasChanged] retain];

            // if desc returns nil, see if we needed UI to resolve
            if (!_desc)
            {
                if (resolveIfRequiresUI)
                    ;  // could not resolve the alias SNG should probably have a warning message or something
                else
                {
                    if (outAliasRequiresUIToResolve)
                        _aliasRequiresUIToResolve = outAliasRequiresUIToResolve;
                }
            }
            
            // aliasHandle changed when it resolved, reset to new aliasHandle
            if (wasChanged)
                [self setAlias:[NSData dataWithCarbonHandle:(Handle)aliasHandle]];
        }
    }
}

- (void)initAlias;
{
    if (!_alias)
    {
        if (_desc && [_desc isValid])
        {
            AliasHandle aliasHandle = [NTAlias aliasHandleForDesc:_desc];
            if (aliasHandle)
                [self setAlias:[NSData dataWithCarbonHandle:(Handle)aliasHandle]];
        }
    }
}

// caller must dispose
- (AliasHandle)aliasHandle;
{
    if (!_aliasHandle)
    {
        if (_alias && [_alias length])
            _aliasHandle = (AliasHandle)[_alias carbonHandle];
    }
    
    return _aliasHandle;
}    

- (void)setAlias:(NSData*)alias;
{
	[alias retain];
    [_alias release];
    _alias = alias;

    if (_aliasHandle)
    {
        DisposeHandle((Handle) _aliasHandle);
        _aliasHandle = nil;
    }
}

@end

@implementation NTAlias (Utilities)

// this routine encapsulates the OS X specific code to resolve an alias
+ (NTFileDesc*)resolveAlias:(AliasHandle)aliasHandle resolveIfRequiresUI:(BOOL)resolveIfRequiresUI outAliasRequiresUIToResolve:(BOOL*)outAliasRequiresUIToResolve outWasChanged:(BOOL*)outWasChanged;
{
    NTFileDesc* result=nil;
    
    if (aliasHandle)
    {
        FSRef targetRef;
        Boolean wasChanged;
        unsigned long mountFlags=0;
        OSErr err;

        if (!resolveIfRequiresUI)
            mountFlags = kResolveAliasFileNoUI;

        err = FSResolveAliasWithMountFlags (NULL, aliasHandle, &targetRef, &wasChanged, mountFlags);

        // I have no idea if this is correct, but it seems to work for server volumes
        if (err)
        {
            if (outAliasRequiresUIToResolve)
                *outAliasRequiresUIToResolve = (err == -35);
        }
        
        if (outWasChanged)
            *outWasChanged = wasChanged;

        if (err == noErr)
		{
            result = [NTFileDesc descFSRef:&targetRef];
			
			// alias may resolve fine if server is mounted, but we still need to mark this alias as a server alias if it is a network volume
            if ([result isNetwork])
            {
                if (outAliasRequiresUIToResolve)
                    *outAliasRequiresUIToResolve = YES;
            }			
		}
    }

    return result;
}

+ (AliasHandle)aliasHandleForDesc:(NTFileDesc*)fileDesc;
{
    AliasHandle resultAlias = nil;
    OSErr err=noErr;

	FSRef* refPtr = [fileDesc FSRefPtr];  // might be computer, make sure we have an FSRef
	if (refPtr)
	{
		err = FSNewAlias(NULL, refPtr, &resultAlias);
		
		if (err)
			resultAlias = nil;
	}

    return resultAlias;
}

+ (NSData*)aliasResourceFromAliasFile:(NTFileDesc*)aliasFile dataFork:(BOOL)dataFork;
{
	NTResourceMgr* mgr = [NTResourceMgr mgrWithDesc:aliasFile useDataFork:dataFork];
	NSData *aliasData = [mgr resourceForType:rAliasType resID:0];
	
	return aliasData;
}

+ (OSType)fileTypeForAliasFileOfDesc:(NTFileDesc*)desc;
{
    OSType type = 0;

    // set alias types for special folders
    if ([desc isApplication])
    {
        if ([desc isPackage])
            type = kAppPackageAliasType;
        else
            type = kApplicationAliasType;
    }
    else if ([desc isVolume])
    {
        if ([desc isNetwork])
            type = kContainerServerAliasType;
        else if ([[desc volume] isCDROM])
            type = kContainerCDROMAliasType;
        else
            type = kContainerHardDiskAliasType;
    }
    else if ([desc isPackage])
        type = kPackageAliasType;
    else if ([desc isDirectory])
        type = kContainerFolderAliasType;

    return type;
}

+ (NTFileDesc*)resolveAliasFile:(NTFileDesc*)aliasFile 
			resolveIfRequiresUI:(BOOL)resolveIfRequiresUI 
	outAliasRequiresUIToResolve:(BOOL*)outAliasRequiresUIToResolve;
{
    NTFileDesc* result=nil;
    
    if ([aliasFile isCarbonAlias])
    {
        FSRef ref = *[aliasFile FSRefPtr];
		Boolean targetIsFolder, wasAliased;
		unsigned long mountFlags=0;
        OSErr err;
		
        if (!resolveIfRequiresUI)
            mountFlags = kResolveAliasFileNoUI;
		
        err = FSResolveAliasFileWithMountFlags (&ref, FALSE, &targetIsFolder, &wasAliased, mountFlags);
		
        // I have no idea if this is correct, but it seems to work for server volumes
        if (err)
        {
            if (outAliasRequiresUIToResolve)
                *outAliasRequiresUIToResolve = (err == -35);
        }
        		
        if (err == noErr)
		{
            result = [NTFileDesc descFSRef:&ref];
			
			// alias may resolve fine if server is mounted, but we still need to mark this alias as a server alias if it is a network volume
            if ([result isNetwork])
            {
                if (outAliasRequiresUIToResolve)
                    *outAliasRequiresUIToResolve = YES;
            }			
		}
    }
	
    return result;
}

@end

