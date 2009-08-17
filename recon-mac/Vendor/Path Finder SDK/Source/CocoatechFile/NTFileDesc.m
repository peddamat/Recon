//
//  NTFileDesc.m
//  CocoatechFile
//
//  Created by sgehrman on Sun Jul 15 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NTFileDesc.h"
#import <sys/stat.h>
#import "NTAliasFileManager.h"
#import "NTVolume.h"
#import "NTFileTypeIdentifier.h"
#import "NTIcon.h"
#import "NTIconStore.h"
#import "NTFSRefObject.h"
#import "NTResourceMgr.h"
#import "NTFileDescMemCache.h"
#import "NTStringShare.h"
#import "NTAlias.h"
#import "NTFileDesc-NTUtilities.h"
#import "NTFileDesc-Private.h"
#import "NTVolumeCache.h"
#import "NTVolumeNotificationMgr.h"
#import "NTMetadata.h"
#import "NTFileDescData.h"
#import "NTCGImage.h"
#import <sys/paths.h>
#import "NTVolumeMgrState.h"

@implementation NTFileDesc

@synthesize cache;
@synthesize FSRefObject;
@synthesize volumeMgrState;

+ (void)initialize;
{
	NTINITIALIZE;
	
	// initialize some singletons
	[self bootVolumeDesc];
}

- (void)updateFSRefObject:(NTFSRefObject*)refObject;
{
    mv_valid = NO;
	
	// a nil refObject means it's the computer
    if (refObject)
	{
		[self setFSRefObject:refObject];
        mv_valid = [[self FSRefObject] isValid];
	}
	else
    {
        mv_isComputer = YES;
		mv_valid = YES;
		
		[self setVolumeMgrState:[NTVolumeMgrState state]];
    }
	
	NTFileDescData *theCache = [[NTFileDescData alloc] init];  // [NTFileDescData cache] avoiding autorelease hit
	[self setCache:theCache];
	[theCache release];
}

- (id)initWithFSRefObject:(NTFSRefObject*)refObject;
{
    self = [super init];
	
    [self updateFSRefObject:refObject];
	
    return self;
}

- (id)initWithPath:(NSString *)path;
{	
    self = [super init];
	
	// nil path is invalid, computer is @""
	if (path)
	{
		NTFSRefObject* refObject=nil;
		if ([path length])
			refObject = [NTFSRefObject refObjectWithPath:path resolvePath:NO];
		
		// if nil, path was zero length (computer)
		[self updateFSRefObject:refObject];
	}
	else
		mv_valid = NO;
	
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
    if ([aCoder allowsKeyedCoding])
	{
		NSString* path = [self path];
		
		if (path)
			[aCoder encodeObject:path forKey:@"path"];
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder;
{
    NSString* path=nil;
	
    if ([aDecoder allowsKeyedCoding])
        path = [aDecoder decodeObjectForKey:@"path"];
	
    if (path)
    {
        self = [self initWithPath:path];
		
        return self;
    }
    
    return nil;
}

- (void)dealloc;
{	
    self.cache = nil;
    self.FSRefObject = nil;
    self.volumeMgrState = nil;
	
    [super dealloc];
}

- (NTFileDesc*)descResolveIfAlias;
{
    return [self descResolveIfAlias:NO];
}

- (NTFileDesc*)descResolveIfAlias:(BOOL)resolveIfServerAlias;
{	
    if ([self isAlias])
	{
		NTFileDesc* resolved = [self resolvedDesc:resolveIfServerAlias];
		
		// could be a server alias that returns nil, or an alias that can't be resolved
		if (resolved) 
			return [[resolved retain] autorelease];
	}
	
    return self;
}

- (NTFileDesc*)aliasDesc; // if we were resolved from an alias, this is the original alias file
{
	if (!mv_valid || mv_isComputer)
        return nil;

	// we store only the path in the cache, this was to avoid a double retain
	// a desc retains it's resolved alias, so the resolved desc can't retain the aliasDesc
	// only used in one part of the code for now, so performance is not necessary
	
	NSString* path=nil;
	if (![[self cache] originalAliasFilePath_initialized:&path])
		; // set in the object internally
		
	if (path)
		return [NTFileDesc descNoResolve:path]; 
	
    return nil;
}

// creates a new copy of the desc (resets mod dates, displayname etc)
- (NTFileDesc*)newDesc;  
{
    NTFileDesc* result;
    
    if ([self isComputer])
        result = [NTFileDesc descNoResolve:@""];
    else
    {
        result = [NTFileDesc descFSRef:[self FSRefPtr]];
        
        // remember originalAliasFilePath if exists
        [result setAliasDesc:[self aliasDesc]];
    }
    
    return result;
}

// is the directory or file open
- (BOOL)isOpen;
{
	BOOL result = NO;
	@synchronized(self) {
		result = [[self FSRefObject] isOpen];
	}
	
	return result;
}

- (NSString*)longDescription;
{
    NSMutableString* result = [NSMutableString stringWithString:[self description]];
	
    [result appendString:@"\n"];
	
	BOOL isOwner = ([[NTUsersAndGroups sharedInstance] userID] == [self ownerID]);
	BOOL isGroup = ([[NTUsersAndGroups sharedInstance] groupID] == [self groupID]);
	BOOL isMemberOfGroup = [[NTUsersAndGroups sharedInstance] userIsMemberOfGroup:[self groupID]];
	
    [result appendString:[NSString stringWithFormat:@"isOwner: %@\n", isOwner?@"YES":@"NO"]];
    [result appendString:[NSString stringWithFormat:@"isGroup: %@\n", isGroup?@"YES":@"NO"]];
    [result appendString:[NSString stringWithFormat:@"isMemberOfGroup: %@\n", isMemberOfGroup?@"YES":@"NO"]];
	
    [result appendString:[[self FSRefObject] description]];
	
    return result;
}

- (NSString*)description;
{
    NSMutableString* result = [NSMutableString stringWithString:@"path:"];
	
	if ([self path])
		[result appendString:[self path]];
	else
		[result appendString:@"<path nil>"];

	[result appendString:@"\n"];
	
	if ([self label])
	{
		[result appendString:[NSString stringWithFormat:@"label: %d", [self label]]];
		[result appendString:@"\n"];
	}
	
    [result appendString:@"valid:"];
    if ([self isValid])
        [result appendString:@"YES"];
    else
        [result appendString:@"NO"];
    [result appendString:@"\n"];
	
    [result appendString:@"volume:"];
    if ([self isVolume])
        [result appendString:@"YES"];
    else
        [result appendString:@"NO"];
	
    if ([self resolvedDesc:NO])
    {
        [result appendString:@"\n"];
        [result appendString:@"resolves to:"];
		
		if ([[self resolvedDesc:NO] path])
			[result appendString:[[self resolvedDesc:NO] path]];
		
        [result appendString:@"\n"];
        [result appendString:@"valid:"];
        if ([[self resolvedDesc:NO] isValid])
            [result appendString:@"YES"];
        else
            [result appendString:@"NO"];
    }
	
    return result;
}

- (BOOL)isComputer
{
    if (!mv_valid)
        return NO;
	
    return mv_isComputer;
}

- (BOOL)isValid
{
    return mv_valid;
}

// could be a path on a disk that was just unmounted.
// double check the file is there
- (BOOL)stillExists;
{
	if (!mv_valid)
		return NO;
	
	if (mv_isComputer)
		return YES;  // computer levels always valid
	
	BOOL result = NO;
	@synchronized(self) {
		result = [[self FSRefObject] stillExists];
	}
	
	return result;
}

- (UInt32)nodeID;
{
    if (!mv_valid || mv_isComputer)
        return 0;
	
	UInt32 result=0;
	if (![[self cache] nodeID_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] nodeID];
		
			[[self cache] setNodeID:result];
		}
    }
	
    return result;
}

- (FSVolumeRefNum)volumeRefNum;
{
    if (!mv_valid || mv_isComputer)
        return 0;
	
	FSVolumeRefNum result=0;
	if (![[self cache] vRefNum_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] volumeRefNum];
			
			[[self cache] setVRefNum:result];
        }
    }
	
    return result;
}

- (NTMetadata*)metadata;
{
	if (!mv_valid || mv_isComputer)
        return nil;

	NTMetadata* result=nil;
	if (![[self cache] metadata_initialized:&result])
	{
		@synchronized(self) {
			result = [NTMetadata metadata:[self path]];
			
			[[self cache] setMetadata:result];
		}
	}
	
	return result;
}

- (NSArray*)FSRefPath:(BOOL)includeSelf;
{
    NSMutableArray* result;
    NTFSRefObject* parent;
	
    // build a path of FSRefs /FSRef/FSRef/FSRef, the order of the array starts with the file and goes until it reaches the volume
    result = [NSMutableArray arrayWithCapacity:6];
	
	@synchronized(self) {
		parent = [self FSRefObject];
		
		if (includeSelf)
			[result addObject:parent];
		
		while (parent)
		{
			parent = [parent parentFSRef];
			
			if (parent)
				[result addObject:parent];
		}
	}
	
    return result;
}

- (BOOL)isParentOfRefPath:(NSArray*)refPath;
{
	if (!mv_valid)
        return NO;
	
	if (mv_isComputer)
		return YES;
	
	BOOL result = NO;
	if ([self isDirectory])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isParentOfRefPath:refPath];
		}
	}
	
	return result;	
}

- (BOOL)isParentOfFSRef:(FSRef*)fsRefPtr;  // used to determine if FSRef is contained by this directory
{
	if (!mv_valid)
        return NO;
	
	if (mv_isComputer)
		return YES;
	
	BOOL result = NO;
	if ([self isDirectory])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isParentOfFSRef:fsRefPtr];
		}
	}
	
	return result;
}

- (BOOL)isParentOfDesc:(NTFileDesc*)desc;  // used to determine if NTFileDesc is contained by this directory
{
	BOOL result = NO;
	
	// same volume?
	if ([self volumeRefNum] == [desc volumeRefNum])
		result = [self isParentOfFSRef:[desc FSRefPtr]];
	
	return result;
}

// if  nil is returned, there is no parent
// not cached since it could become invalid if parent renamed
- (NTFileDesc *)parentDesc;
{
	if (!mv_valid || mv_isComputer)
        return nil;
	
	NTFileDesc* result=nil;
	
	@synchronized(self) {
		NTFSRefObject* parentRef = [[self FSRefObject] parentFSRef];
		
		if (parentRef)
			result = [NTFileDesc descFSRefObject:parentRef];
	}			
	
    return result;
}

- (UInt32)parentDirID;
{
    if (!mv_valid || mv_isComputer)
        return 0;
	
	UInt32 result=0;
	if (![[self cache] parentDirID_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] parentDirID];
			
			[[self cache] setParentDirID:result];
		}
    }
	
    return result;
}

- (BOOL)parentIsVolume;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isParentAVolume_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] parentIsVolume];
		
			[[self cache] setIsParentAVolume:result];
		}
    }
	
    return result;
}

// forDisplay will give you "" when asking for the parent of a volume instead of /Volumes
- (NSString *)parentPath:(BOOL)forDisplay;
{
    NSString* result;
	
    if (!mv_valid)
        return @"";
	
    result = [[self path] stringByDeletingLastPathComponent];
    if (!result)
        return @"";
	
    // we don't want the parent of /Volumes/disk1 to be /Volumes, just take them back to @""
    if (forDisplay)
    {
        if ([result isEqualToString:@"/Volumes"])
            return @"";
    }
	
    if ([result isEqualToString:[self path]])
        return @"";
	
    return result;
}

- (NTFileDesc *)application;
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NTFileDesc* result=nil;
	if (![[self cache] application_initialized:&result])
	{
		@synchronized(self) {
			if ([self FSRefPtr])
			{
				OSStatus err;
				FSRef outAppRef;
				
				err = LSGetApplicationForItem([self FSRefPtr], kLSRolesAll, &outAppRef, NULL);
				if (err == noErr)
					result = [NTFileDesc descFSRef:&outAppRef];					
			}
			
			[[self cache] setApplication:result];
		}
    }
	
    return result;
}

- (BOOL)applicationCanOpenFile:(NTFileDesc*)droppedFile;
{
    BOOL result=NO;
	
    if (!mv_valid || mv_isComputer)
        return NO;
	
    if ([self isApplication])
    {
        Boolean outAcceptsItem;
        OSStatus err;
		
        if ([droppedFile FSRefPtr] && [self FSRefPtr])
        {
            err = LSCanRefAcceptItem([droppedFile FSRefPtr],
                                     [self FSRefPtr],
                                     kLSRolesViewer,
                                     kLSAcceptDefault, &outAcceptsItem);
			
            if (err == noErr)
                result = outAcceptsItem;
        }
    }
	
    return result;
}

- (NSString *)name;
{
    if (!mv_valid || mv_isComputer)
        return @"";
    
	NSString *result=nil;
	@synchronized(self) {
		result = [[self FSRefObject] name];
	}    
	
    return result;
}

- (NSString *)path;
{
	if (!mv_valid)
		return nil;
	
	if (mv_isComputer)
		return @"";
		
	NSString* result=nil;
	@synchronized(self) {
		result = [[self FSRefObject] path];
	}
    
    return result;
}

- (NTFileTypeIdentifier*)typeIdentifier;
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NTFileTypeIdentifier* result=nil;
	if (![[self cache] typeIdentifier_initialized:&result])
	{
		@synchronized(self) {
			result = [NTFileTypeIdentifier typeIdentifier:self];
			
			[[self cache] setTypeIdentifier:result];
		}
    }
	
    return result;
}

- (NSString *)extension;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![[self cache] extension_initialized:&result])
	{
		@synchronized(self) {
			result = [[self nameWhenCreated] strictPathExtension];
			result = [[NTStringShare sharedInstance] sharedExtensionString:result];
			
			[[self cache] setExtension:result];
		}
    }
	
    return result;
}

- (BOOL)isFile;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isFile_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isFile];
			
			[[self cache] setIsFile:result];
		}
	}
	
	return result;
}

- (BOOL)isDirectory;
{
    if (!mv_valid)
        return NO;
    else if (mv_isComputer)
        return YES;
	
    return ![self isFile];
}

- (BOOL)isOnBootVolume;
{
	return ([self volumeRefNum] == [[NTFileDesc bootVolumeDesc] volumeRefNum]);
}

- (BOOL)isNameLocked;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isNameLocked_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isNameLocked];
			
			[[self cache] setIsNameLocked:result];
		}
    }
	
    return result;
}

- (BOOL)isLocked;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isLocked_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isLocked];
			
			[[self cache] setIsLocked:result];
        }
    }
	
    return result;
}

- (NSString*)dictionaryKey;
{
    if (!mv_valid)
        return @"";
	
	// return computer for computer level
	if (mv_isComputer)
		return @"Computer";
	
	NSString* result=nil;
	if (![[self cache] dictionaryKey_initialized:&result])
	{
		@synchronized(self) {
			// I was using the parentDirID, but this would fail in some cases where the file was moved to a different directory and the FSRef was still the same
			// don't use name in the key, the name could change and might break some code
			result = [NSString stringWithFormat:@"%d:%d", [self nodeID], [self volumeRefNum]];
			
			[[self cache] setDictionaryKey:result];
		}
	}
	
    return result;
}

// like dictionaryKey, but adds the parentDirID so you can know if the item moved for example
- (NSString*)strictDictionaryKey;
{
	if (!mv_valid)
        return @"";
	
	// return computer for computer level
	if (mv_isComputer)
		return @"Computer";
	
	NSString* result=nil;
	if (![[self cache] strictDictionaryKey_initialized:&result])
	{
		@synchronized(self) {
			result = [NSString stringWithFormat:@"%d:%d:%d", [self nodeID], [self volumeRefNum], [self parentDirID]];
			
			[[self cache] setStrictDictionaryKey:result];
		}
	}
	
    return result;	
}

- (BOOL)hasCustomIcon;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] hasCustomIcon_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] hasCustomIcon];
			
			[[self cache] setHasCustomIcon:result];
        }
    }
	
    return result;
}

- (BOOL)isStationery;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isStationery_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isStationery];
			
			[[self cache] setIsStationery:result];
        }
    }
	
    return result;
}

- (BOOL)isBundleBitSet
{
    if (!mv_valid || mv_isComputer)
        return NO;
    
	BOOL result=NO;
	if (![[self cache] isBundleBitSet_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isBundleBitSet];
			
			[[self cache] setIsBundleBitSet:result];
        }
    }
    
    return result;    
}

- (NSString*)bundleSignature;
{
	if (!mv_valid)
        return @"";
	
	NSString* result=nil;
	if (![[self cache] bundleSignature_initialized:&result])
	{
		@synchronized(self) {
			if ([self isPackage]) 
			{
				NSBundle* bundle = [NSBundle bundleWithPath:[self path]];
				if (bundle) 
					result = [[bundle infoDictionary] stringForKey:@"CFBundleSignature"];
			}
			
			if (!result)
				result = @"";
			
			[[self cache] setBundleSignature:result];
		}
	}
	
	return result;
}

- (NSString*)bundleIdentifier;
{
	if (!mv_valid)
        return @"";
	
	NSString* result=nil;
	if (![[self cache] bundleIdentifier_initialized:&result])
	{
		@synchronized(self) {
			if ([self isPackage]) 
			{
				NSBundle* bundle = [NSBundle bundleWithPath:[self path]];
				if (bundle) 
					result = [bundle bundleIdentifier];
			}
			
			if (!result)
				result = @"";
			
			[[self cache] setBundleIdentifier:result];
		}
	}
	
	return result;
}

- (BOOL)isAliasBitSet;
{
    if (!mv_valid || mv_isComputer)
        return NO;
    
	BOOL result=NO;
	if (![[self cache] isAliasBitSet_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isAliasBitSet];
			
			[[self cache] setIsAliasBitSet:result];
        }
    }
    
    return result;    
}

- (NSString*)executablePath;
{
    NSString* result = nil;

	// frameworks, plugins, apps, not all are packages, so removed check
	if ([self isDirectory])
	{
		NSBundle *bundle = [NSBundle bundleWithPath:[self path]];
		if (bundle)
			result = [bundle executablePath];
	}
	
	return result;
}

- (BOOL)isReadable;
{
	/*
	 Each level is independent. The user who is trying to access the file determines what level will be used to set permissions.
	 
	 If the user is the owner of the file, the owner permissions will be used.
	 If the user is not the owner of the file but is in the same group as the file, the group permissions will be used.
	 If the user is not the owner of the file and is not in the same group as the file, the other permissions will be used.
	 
	 NOTE: access() resolves symlinks
	 */
	
    if (!mv_valid)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isReadable_initialized:&result])
	{
		// computer fake directory is readable
		if (mv_isComputer)
			result = YES;
		
		// are we logged in as root?
		if (!result)
		{
			if ([[NTUsersAndGroups sharedInstance] isRoot])
				result = YES;
		}
		
		if (!result)
		{
			BOOL isOwner = ([[NTUsersAndGroups sharedInstance] userID] == [self ownerID]);
			
			// test if owner
			if (!result)
			{
				if (isOwner)
					result = (([self posixPermissions] & S_IRUSR) == S_IRUSR);
			}
			
			// test if group
			if (!result)
			{
				BOOL isGroup = (([[NTUsersAndGroups sharedInstance] groupID] == [self groupID]) || 
								[[NTUsersAndGroups sharedInstance] userIsMemberOfGroup:[self groupID]]);
				
				if (isGroup)
					result = (([self posixPermissions] & S_IRGRP) == S_IRGRP);
				
				// is the item readable by everyone?
				if (!result)
				{
					if (!isGroup && !isOwner)
						result = (([self posixPermissions] & S_IROTH) == S_IROTH);			
				}
			}
		}
		
		[[self cache] setIsReadable:result];
	}
	
	return result;
}

- (BOOL)isWritable;
{
	/*
	 Each level is independent. The user who is trying to access the file determines what level will be used to set permissions.
	 
	 If the user is the owner of the file, the owner permissions will be used.
	 If the user is not the owner of the file but is in the same group as the file, the group permissions will be used.
	 If the user is not the owner of the file and is not in the same group as the file, the other permissions will be used.
	 
	 NOTE: access() resolves symlinks
	 */
	
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isWritable_initialized:&result])
	{
		// are we on a CD rom, or is the item locked?
		if (![self isVolumeReadOnly] && ![self isLocked])
		{
			// are we logged in as root?
			if ([[NTUsersAndGroups sharedInstance] isRoot])
				result = YES;
			
			if (!result)
			{
				BOOL isOwner = ([[NTUsersAndGroups sharedInstance] userID] == [self ownerID]);
				
				// then if we are the owner, is there owner permissions
				if (!result)
				{
					if (isOwner)
						result = (([self posixPermissions] & S_IWUSR) == S_IWUSR);
				}
				
				if (!result)
				{
					// checking group can be slow
					BOOL isGroup = (([[NTUsersAndGroups sharedInstance] groupID] == [self groupID]) || 
									[[NTUsersAndGroups sharedInstance] userIsMemberOfGroup:[self groupID]]);
					
					if (isGroup)
						result = (([self posixPermissions] & S_IWGRP) == S_IWGRP);
					
					// is the item writable by everyone?
					if (!result)
					{
						// other is only valid if we are not the group or owner
						if (!isGroup && !isOwner)
							result = (([self posixPermissions] & S_IWOTH) == S_IWOTH);	
					}
				}
			}
		}
		
		[[self cache] setIsWritable:result];
    }
	
    return result;
}

- (BOOL)isExecutable;
{
	/*
	 Each level is independent. The user who is trying to access the file determines what level will be used to set permissions.
	 
	 If the user is the owner of the file, the owner permissions will be used.
	 If the user is not the owner of the file but is in the same group as the file, the group permissions will be used.
	 If the user is not the owner of the file and is not in the same group as the file, the other permissions will be used.
	 
	 NOTE: access() resolves symlinks
	 */
	
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isExecutable_initialized:&result])
	{
		// are we logged in as root?
		if (!result)
		{
			if ([[NTUsersAndGroups sharedInstance] isRoot])
				result = YES;
		}
		
		if (!result)
		{
			BOOL isOwner = ([[NTUsersAndGroups sharedInstance] userID] == [self ownerID]);
			
			// test if owner
			if (!result)
			{
				if (isOwner)
					result = (([self posixPermissions] & S_IXUSR) == S_IXUSR);
			}
			
			// test if group
			if (!result)
			{
				BOOL isGroup = (([[NTUsersAndGroups sharedInstance] groupID] == [self groupID]) || 
								[[NTUsersAndGroups sharedInstance] userIsMemberOfGroup:[self groupID]]);
				
				if (isGroup)
					result = (([self posixPermissions] & S_IXGRP) == S_IXGRP);
				
				// is the item executable by everyone?
				if (!result)
				{
					if (!isGroup && !isOwner)
						result = (([self posixPermissions] & S_IXOTH) == S_IXOTH);			
				}
			}
		}
		
		[[self cache] setIsExecutable:result];
	}
	
	return result;
}

- (BOOL)isDeletable;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isDeletable_initialized:&result])
	{
		@synchronized(self) {
			if (![self isVolume])
				result = [[NSFileManager defaultManager] isDeletableFileAtPath:[self path]];
			
			[[self cache] setIsDeletable:result];
        }
    }
	
    return result;
}

// can we move the file?
- (BOOL)isMovable;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isMovable_initialized:&result])
	{
		@synchronized(self) {
			NTFileDesc* parentDesc = [self parentDesc];
			
			if ([parentDesc isWritable]  && ![self isLocked]) // can't move locked files (same as finder)
			{
				result = YES;
				
				// directories keep track of their parent (..), so we need to be writable to be movable.  Files do not keep track of the parent (..)
				if ([self isDirectory])
					result = [self isWritable];
				
				if (result)
				{
					// A directory whose `sticky bit' is set becomes an append-only directory,
					// or, more accurately, a directory in which the deletion of files is
					// restricted.  A file in a sticky directory may only be removed or renamed
					// by a user if the user has write permission for the directory and the user
					// is the owner of the file, the owner of the directory, or the super-user.
					if ([parentDesc isStickyBitSet] && ![[NTUsersAndGroups sharedInstance] isRoot])
					{
						result = NO;
						
						int myUserID = [[NTUsersAndGroups sharedInstance] userID];
						
						// owner of the file or owner of the parent directory
						if (([parentDesc ownerID] == myUserID) || ([self ownerID] == myUserID))
							result = YES;
					}
				}
			}
			
			[[self cache] setIsMovable:result];
        }
    }
	
    return result;
}

// read only even if we had admin privleges
- (BOOL)isReadOnly;
{
	if (!mv_valid || mv_isComputer)
        return YES;

	BOOL result=NO;
	if (![[self cache] isReadOnly_initialized:&result])
	{
		@synchronized(self) {
			if ([self isLocked] || [[self volume] isReadOnly])
				result = YES;
			
			[[self cache] setIsReadOnly:result];
        }
    }
	
    return result;
}

- (BOOL)isRenamable;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isRenamable_initialized:&result])
	{
		@synchronized(self) {
			if (![self isLocked])  // took out the "![self isNameLocked]" check, Finder ignores it
			{
				// are we a volume?
				if ([self isVolume])
				{
					if (![self isVolumeReadOnly] && ![self isNetwork])
						result =  YES;
				}
				else
					result = [self isMovable];  // same requirements as movable
			}
			
			[[self cache] setIsRenamable:result];
        }
    }
	
    return result;
}

- (BOOL)isAlias;
{
    return ([self isSymbolicLink] || [self isCarbonAlias] || [self isPathFinderAlias]);
}

- (BOOL)isCarbonAlias;
{
    if (!mv_valid || mv_isComputer)
        return NO;
    
	BOOL result=NO;
	if (![[self cache] isCarbonAlias_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isCarbonAlias];
			
			[[self cache] setIsCarbonAlias:result];
        }
    }
    
    return result;
}

- (BOOL)isPathFinderAlias;
{
    if (!mv_valid || mv_isComputer)
        return NO;
    
	BOOL result=NO;
	if (![[self cache] isPathFinderAlias_initialized:&result])
	{
		@synchronized(self) {
			result = [[self extension] isEqualToStringCaseInsensitive:kPathFinderAliasExtension];
			
			[[self cache] setIsPathFinderAlias:result];
        }
    }
    
    return result;
}

- (BOOL)isSymbolicLink;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isSymbolicLink_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isSymbolicLink];
			
			[[self cache] setIsSymbolicLink:result];
        }
    }
	
    return result;
}

- (BOOL)isStickyBitSet;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isStickyBitSet_initialized:&result])
	{
		@synchronized(self) {
			result = ((S_ISVTX & [[self FSRefObject] modeBits]) != 0);
			
			[[self cache] setIsStickyBitSet:result];
        }
    }
	
    return result;
}

- (BOOL)isPipe;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isPipe_initialized:&result])
	{
		@synchronized(self) {
			result = ((S_IFIFO & [[self FSRefObject] modeBits]) != 0);
			
			[[self cache] setIsPipe:result];
        }
    }
	
    return result;
}

- (BOOL)isVolume;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isVolume_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isVolume];
						
			[[self cache] setIsVolume:result];
        }
    }
	
    return result;
}

- (int)label;
{
	if (!mv_valid || mv_isComputer)
        return 0;
	
	UInt32 result=0;
	if (![[self cache] label_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] fileLabel];
			
			[[self cache] setLabel:result];
		}
    }
	
    return result;
}

- (int)type;
{
	if (!mv_valid || mv_isComputer)
        return 0;
	
	UInt32 result=0;
	if (![[self cache] type_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] fileType];
			
			[[self cache] setType:result];
		}
    }
	
    return result;
}

- (int)creator;
{
	if (!mv_valid || mv_isComputer)
        return 0;
	
	UInt32 result=0;
	if (![[self cache] creator_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] fileCreator];
			
			[[self cache] setCreator:result];
		}
    }
	
    return result;
}

- (UInt64)rsrcForkSize;
{    
	if (!mv_valid || mv_isComputer || ![self isFile])
		return 0;
	
    UInt64 result=0;
	if (![[self cache] rsrcForkSize_initialized:&result])
	{
		@synchronized(self) {
			[self initializeSizeInfo];
		}
		
		// get the result
		[[self cache] rsrcForkSize_initialized:&result];
    }
    
    return result;
}

- (UInt64)dataForkSize;
{
	if (!mv_valid || mv_isComputer || ![self isFile])
		return 0;
	
    UInt64 result=0;
	if (![[self cache] dataForkSize_initialized:&result])
	{
		@synchronized(self) {
			[self initializeSizeInfo];
		}
		
		// get the result
		[[self cache] dataForkSize_initialized:&result];
    }
    
    return result;
}

- (UInt64)rsrcForkPhysicalSize;
{    
	if (!mv_valid || mv_isComputer || ![self isFile])
		return 0;
	
    UInt64 result=0;
	if (![[self cache] rsrcForkPhysicalSize_initialized:&result])
	{
		@synchronized(self) {
			[self initializeSizeInfo];
		}
		
		// get the result
		[[self cache] rsrcForkPhysicalSize_initialized:&result];
    }
    
    return result;
}

- (UInt64)dataForkPhysicalSize;
{
	if (!mv_valid || mv_isComputer || ![self isFile])
		return 0;
	
    UInt64 result=0;
	if (![[self cache] dataForkPhysicalSize_initialized:&result])
	{
		@synchronized(self) {
			[self initializeSizeInfo];
		}
		
		// get the result
		[[self cache] dataForkPhysicalSize_initialized:&result];
    }
    
    return result;
}

// total size of all forks or folder size if set
- (UInt64)size;
{
	if (!mv_valid || mv_isComputer || ![self isFile])
        return 0;
	
	UInt64 result=0;
	if (![[self cache] fileSize_initialized:&result])
	{
		@synchronized(self) {
			[self initializeSizeInfo];
		}
		
		// get the result
		[[self cache] fileSize_initialized:&result];
	}
	
    return result;
}

// total size of all forks or folder size if set
- (UInt64)physicalSize;
{
	if (!mv_valid || mv_isComputer || ![self isFile])
        return 0;
	
	UInt64 result=0;
	if (![[self cache] physicalFileSize_initialized:&result])
	{
		@synchronized(self) {
			[self initializeSizeInfo];
		}
		
		// get the result
		[[self cache] physicalFileSize_initialized:&result];
	}
	
    return result;
}

- (UInt32)valence;  // only valid for folders, 0 if file or invalid
{
    if (!mv_valid || mv_isComputer || [self isFile])
        return 0;
    
	UInt32 result=0;
	if (![[self cache] valence_initialized:&result])
	{
		@synchronized(self) {			
			// don't call unless a native HFS disk
			if ([[self volume] isHFS])
				result = [[self FSRefObject] valence];
			
			[[self cache] setValence:result];
		}
	}
	
    return result;
}

- (UInt32)posixPermissions;
{
    if (!mv_valid || mv_isComputer)
        return 0;
	
	UInt32 result=0;
	if (![[self cache] posixPermissions_initialized:&result])
	{
		@synchronized(self) {
			result = ([[self FSRefObject] modeBits] & ACCESSPERMS);
		
			[[self cache] setPosixPermissions:result];
		}
    }
	
    return result;
}

- (UInt32)posixFileMode;
{
    if (!mv_valid || mv_isComputer)
        return 0;
	
	UInt32 result=0;
	if (![[self cache] posixFileMode_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] modeBits];
		
			[[self cache] setPosixFileMode:result];
		}
    }
	
    return result;
}

- (BOOL)isExecutableBitSet;
{
	UInt32 perm = [self posixPermissions];
	
    if ( ((perm & S_IXUSR) == S_IXUSR) ||
		 ((perm & S_IXGRP) == S_IXGRP) ||
		 ((perm & S_IXOTH) == S_IXOTH) )
        return YES;
    
    return NO;
}

- (NSString*)permissionString;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![[self cache] permissionString_initialized:&result])
	{
		@synchronized(self) {
			result = [NTFileDesc permissionsTextForDesc:self includeOctal:YES];
			
			[[self cache] setPermissionString:result];
		}
    }
	
    return result;
}

- (UInt32)ownerID;
{
	if (!mv_valid || mv_isComputer)
        return 0;
	
	UInt32 result=0;
	if (![[self cache] ownerID_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] ownerID];
			
			[[self cache] setOwnerID:result];
		}
    }
	
    return result;
}

- (NSString *)ownerName;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![[self cache] ownerName_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] ownerName];
			
			[[self cache] setOwnerName:result];
		}
    }
	
    return result;
}

- (UInt32)groupID;
{
	if (!mv_valid || mv_isComputer)
        return 0;

	UInt32 result=0;
	if (![[self cache] groupID_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] groupID];
			
			[[self cache] setGroupID:result];
		}
    }
	
    return result;
}

- (NSString *)groupName;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![[self cache] groupName_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] groupName];
			
			[[self cache] setGroupName:result];
		}
    }
	
    return result;
}

- (NSDate*)modificationDate
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NSDate* result=nil;
	if (![[self cache] modificationDate_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] modificationDate];
			
			[[self cache] setModificationDate:result];
		}
	}
	
	return result;
}

- (NSDate*)creationDate
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NSDate* result=nil;
	if (![[self cache] creationDate_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] creationDate];
			
			[[self cache] setCreationDate:result];
		}
	}
	
    return result;
}

// time of last file status change, rename, permissions etc
- (NSDate*)attributeModificationDate;
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NSDate* result=nil;
	if (![[self cache] attributeDate_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] attributeModificationDate];
			
			[[self cache] setAttributeDate:result];
		}
	}
	
    return result;
}

- (NSDate*)accessDate;
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NSDate* result=nil;
	if (![[self cache] accessDate_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] accessDate];
			
			[[self cache] setAccessDate:result];
		}
	}
	
    return result;
}

- (BOOL)hasBeenModified
{
    if (!mv_valid)
        return NO;
    
	BOOL result=NO;
	[[self cache] hasBeenModified_initialized:&result];
	
	// once it's been modifed, don't check again, but check if still == 0
	if (!result)
	{
		@synchronized(self) {
			if (mv_isComputer)
			{
				// if the computer level, check the number of mounted volume to see if it has changed
				if ([[self volumeMgrState] changed])
					result = YES;
			}
			else
				result = [[self FSRefObject] hasBeenModified];
			
			[[self cache] setHasBeenModified:result];
		}
	}
	
    return result;
}

- (BOOL)hasBeenRenamed;
{
    if (!mv_valid)
        return NO;
    
	BOOL result=NO;
	[[self cache] hasBeenRenamed_initialized:&result];
	
	// once it's been renamed, don't check again, but check if still == 0
	if (!result)
	{
		@synchronized(self) {
			result = [[self FSRefObject] hasBeenRenamed];
			
			[[self cache] setHasBeenRenamed:result];
		}
	}
	
    return result;
}

- (NSString*)nameWhenCreated;
{
	if (!mv_valid)
        return @"";
	
	NSString *result;
	@synchronized(self) {
		result = [[self FSRefObject] nameWhenCreated];  // string doesn't change, so no need to worry about thread safety issues
	}
	
	return result;
}

- (const FileInfo*)fileInfo;
{
    if (!mv_valid || mv_isComputer)
        return nil;
    
    return [[self FSRefObject] fileInfo];
}

// slow, not cached
- (NSURL*)URL;
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NSURL* result=nil;
	@synchronized(self) {
		result = [[self FSRefObject] URL];
	}
	
    return result;
}

- (NSString*)comments;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![[self cache] comments_initialized:&result])
	{
		@synchronized(self) {
			result = [[self metadata] valueForAttribute:(NSString*)kMDItemFinderComment];
			
			if (!result)
				result = @"";
			
			[[self cache] setComments:result];
		}
	}
	
	return result;
}

- (NSDate*)lastUsedDate;
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NSDate* result=nil;
	if (![[self cache] lastUsedDate_initialized:&result])
	{
		@synchronized(self) {
			result = [[self metadata] valueForAttribute:(NSString*)kMDItemLastUsedDate];
						
			if (result)
				[[self cache] setLastUsedDate:result];
		}
	}
		
	return result;
}

- (NSPoint)finderPosition;
{
    if (!mv_valid || mv_isComputer)
        return NSZeroPoint;
	
    NSPoint result=NSZeroPoint;
	@synchronized(self) {
		result = [[self FSRefObject] finderPosition];
	}
	
	return result;
}

- (NSString*)versionString;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![[self cache] version_initialized:&result])
	{
		@synchronized(self) {			
			// localizedInfoDictionary was crashing on volumes, so I added the package test
			if ([self isPackage])
			{
				NSBundle *bundle = [NSBundle bundleWithPath:[self path]];
				if (bundle)
				{
					NSDictionary *dict = [bundle localizedInfoDictionary];
					if (dict)
						result = [dict objectForKey:@"CFBundleShortVersionString"];
					
					if (!result)
					{
						NSDictionary *dict = [bundle infoDictionary];
						if (dict)
							result = [dict objectForKey:@"CFBundleShortVersionString"];
					}
				}
			}
			
			// we didn't find a version, is this a carbon or classic app?
			if (!result && [self isFile])
				result = [self carbonVersionString:YES];
			
			if (!result)
				result = @"";
			
			[[self cache] setVersion:result];
		}
    }
	
    return result;
}

- (NSString*)bundleVersionString;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![[self cache] bundleVersion_initialized:&result])
	{
		@synchronized(self) {			
			// localizedInfoDictionary was crashing on volumes, so I added the package test
			if ([self isPackage])
			{
				NSBundle *bundle = [NSBundle bundleWithPath:[self path]];
				if (bundle)
				{
					NSDictionary *dict = [bundle localizedInfoDictionary];
					if (dict)
						result = [dict objectForKey:@"CFBundleVersion"];
					
					if (!result)
					{
						NSDictionary *dict = [bundle infoDictionary];
						if (dict)
							result = [dict objectForKey:@"CFBundleVersion"];
					}
				}
			}
			
			if (!result)
				result = @"";
				
			[[self cache] setBundleVersion:result];
		}
    }
	
    return result;
}

- (NSString*)infoString;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![[self cache] getInfo_initialized:&result])
	{
		@synchronized(self) {			
			// localizedInfoDictionary was crashing on volumes, so I added the package test
			if ([self isPackage])
			{
				NSBundle *bundle = [NSBundle bundleWithPath:[self path]];
				if (bundle)
				{
					NSDictionary *dict = [bundle localizedInfoDictionary];
					if (dict)
						result = [dict objectForKey:@"CFBundleGetInfoString"];
					
					if (!result)
					{
						NSDictionary *dict = [bundle infoDictionary];
						if (dict)
							result = [dict objectForKey:@"CFBundleGetInfoString"];
					}
				}
			}
			
			// we didn't find info, is this a carbon or classic app?
			if (!result)
				result = [self carbonVersionString:NO];
			
			if (!result)
				result = @"";
			
			[[self cache] setGetInfo:result];
		}
    }
	
    return result;
}

- (const char *)UTF8Path;
{
    if (!mv_valid || mv_isComputer)
        return nil;  // computer is not a valid path to a filesystem call
    
    return [[self path] UTF8String];    
}

- (const char *)fileSystemPath;
{
    if (!mv_valid || mv_isComputer)
        return nil;  // computer is not a valid path to a filesystem call
	
    return [[self path] fileSystemRepresentation];
}

- (FSRef*)FSRefPtr;
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
    return [[self FSRefObject] ref];
}

- (BOOL)isBrokenAlias;
{
	if (!mv_valid || mv_isComputer)
		return NO;

	BOOL result=NO;
	if (![[self cache] isBrokenAlias_initialized:&result])
	{
		@synchronized(self) {
			[self resolvedDesc:NO];
			
			// get the result, set in resolvedDesc
			[[self cache] isBrokenAlias_initialized:&result];
		}
	}

	return result;
}

- (BOOL)isServerAlias;
{
	if (!mv_valid || mv_isComputer)
		return NO;

	BOOL result=NO;
	if (![[self cache] isServerAlias_initialized:&result])
	{
		@synchronized(self) {
			[self resolvedDesc:NO];
			
			// get the result, set in resolvedDesc
			[[self cache] isServerAlias_initialized:&result];
		}
	}
	
    return result;
}

- (NTIcon*)icon;
{
    if (!mv_valid)
        return nil;
	
	NTIcon* result=nil;
	if (![[self cache] icon_initialized:&result])
	{
		@synchronized(self) {
			if (mv_isComputer)
				result = [[NTIconStore sharedInstance] computerIcon];
			else
				result = [[self FSRefObject] icon];
			
			// not sure why this would happen, but if we fail to get the icon, get a generic document or folder
			if (!result)
			{
				if ([self isDirectory])
					result = [[NTIconStore sharedInstance] folderIcon];
				else
					result = [[NTIconStore sharedInstance] documentIcon];
			}            
			
			[[self cache] setIcon:result];
		}
	}
	
    return result;
}

// only to be used for unix tools that need a path
- (NSString*)pathToResourceFork;
{
    NSString* result=nil;
		
	// only for files
	if ([self isFile])
	{
		if ([[self volume] supportsForks])
			result = [[self path] stringByAppendingFormat:@"%s", _PATH_RSRCFORKSPEC];
		else
		{
			NSString* rsrcName = [@"._" stringByAppendingString:[self name]];
			NTFileDesc* parentDesc = [self parentDesc];
			
			if (parentDesc)
				result = [[parentDesc path] stringByAppendingPathComponent:rsrcName];
		}
	}
		
    return result;
}

// strips out /Volumes automatically (unless the path is /Volumes)
- (NSArray*)pathComponents:(BOOL)resolveAliases;
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:5];
	
    if (!mv_valid || mv_isComputer)
        return result;
    
    NSArray* pathComponents = [[self path] pathComponents];
    int i, cnt = [pathComponents count];
    BOOL stripVolumes = NO;
    NSString* volumes = @"/Volumes";
    NSString* path;
    
    // look for @"/Volumes", be sure not to strip out /Volumes if that is the path
    if ([[self path] length] > [volumes length])
    {
        if ([[self path] compare:volumes options:0 range:NSMakeRange(0, [volumes length])] == NSOrderedSame)
            stripVolumes = YES;
    }
    
    path = @"";
    for (i=0;i<cnt;i++)
    {
        path = [path stringByAppendingPathComponent:[pathComponents objectAtIndex:i]];
        
        if (stripVolumes && (i < 2))
            ;
        else
        {
            NTFileDesc* desc=nil;
            
            if (resolveAliases)
                desc = [NTFileDesc descResolve:path];
            else
                desc = [NTFileDesc descNoResolve:path];
            
            if (desc)
                [result addObject:desc];
        }
    }
    
    return result;
}

- (BOOL)catalogInfo:(FSCatalogInfo*)outCatalogInfo bitmap:(FSCatalogInfoBitmap)bitmap;
{
    FSCatalogInfo* info=nil;
	
    if (!mv_valid || mv_isComputer)
        return NO;
	
	@synchronized(self) {
		// make sure the info we want has been set
		[[self FSRefObject] updateCatalogInfo:bitmap];
		
		// catalogInfo can return nil if it's invalid
		info = [[self FSRefObject] catalogInfo];
		if (info)
			*outCatalogInfo = *info;
	}
	
    return (info != nil);
}

- (NSString*)itemInfo;
{
	if (!mv_valid)
        return @"";
	
	NSString* result=nil;
	if (![[self cache] itemInfo_initialized:&result])
	{
		@synchronized(self) {
			if ([self isVolume])
				result = [self volumeInfoString];
			else if ([[self volume] isHFS] && ![self isPackage] && [self isDirectory])
			{
				int count = [self valence];
				
				if (count == 0)
					result = [NTLocalizedString localize:@"No items"];
				else if (count == 1)
					result = [NTLocalizedString localize:@"1 item"];
				else if (count > 1)
					result = [NSString stringWithFormat:[NTLocalizedString localize:@"%d items"], count];
			}
			else if ([[self typeIdentifier] isAudio] || [[self typeIdentifier] isMovie])
			{
				result = [[self metadata] displayValueForAttribute:(NSString*)kMDItemDurationSeconds];
				
				if ([result length] && [self isFile])  // return the size for normal files
					result = [NSString stringWithFormat:@"%@ / %@", result, [[NTSizeFormatter sharedInstance] fileSize:[self size]]];
			}
			else if ([[self typeIdentifier] isImageForPreview])
			{
				result = [[self metadata] imageSizeStringMD];

				// not all image meta data contains size
				if (![result length])
					result = [NTCGImage imageSizeString:self];
				
				// also add the file size if we get the image size
				if ([result length])
				{
					if ([self isFile])  // return the size for normal files
						result = [NSString stringWithFormat:@"%@ / %@", result, [[NTSizeFormatter sharedInstance] fileSize:[self size]]];
				}
			}
			
			if (![result length])
			{
				if ([self isFile])  // return the size for normal files
					result = [[NTSizeFormatter sharedInstance] fileSize:[self size]];
			}
			
			if (!result)
				result = @"";
			
			[[self cache] setItemInfo:result];
		}
	}
	
    return result;
}

- (NSString*)uniformTypeID;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![[self cache] uniformTypeID_initialized:&result])
	{
		@synchronized(self) {
			CFTypeRef outString = nil;
			if ([self FSRefPtr])
			{
				OSStatus err = LSCopyItemAttribute([self FSRefPtr],
												   kLSRolesAll,
												   kLSItemContentType, &outString);
				
				if (err == noErr)
					result = (NSString*)outString;
			}
			
			if (!result)
				result = @"";
			
			[[self cache] setUniformTypeID:result];

			if (outString)
				CFRelease(outString);
		}
	}
	
	return result;
}

- (BOOL)isInvisible;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isInvisible_initialized:&result])
	{
		@synchronized(self) {
			if ([self FSRefPtr])
			{
				CFTypeRef outBool;
				OSStatus err = LSCopyItemAttribute([self FSRefPtr],
												   kLSRolesAll,
												   kLSItemIsInvisible, &outBool);
				
				if (!err)
				{
					result = [(NSNumber*) outBool boolValue];
					CFRelease(outBool);
				}
				
				if (!result)
					result = [self isUnixFileThatShouldBeHidden];
			}
			
			[[self cache] setIsInvisible:result];
		}
	}
	
    return result;
}

// we are caching the displayName, this is slow, and not so critical if different just used for display
- (NSString*)displayName;
{
    if (!mv_valid)
        return @"";
	
	NSString* result=nil;
	if (![[self cache] displayName_initialized:&result])
	{
		@synchronized(self) {
			CFTypeRef outString=nil;
			if (mv_isComputer)
				result = [NTLocalizedString localize:@"Computer" table:@"CocoaTechFoundation"];
			else
			{
				if ([self FSRefPtr])
				{
					OSStatus err = LSCopyItemAttribute([self FSRefPtr],
													   kLSRolesAll,
													   kLSItemDisplayName, &outString);
					
					if (!err)
						result = (NSString*)outString;
				}
			}
			
			// if no displayName, set to name
			if (!result)
				result = [self name];
			
			[[self cache] setDisplayName:result];
			
			// release the outString
			if (outString)
				CFRelease(outString);
		}
	}
	
    return result;
}

- (NSString*)displayPath;
{
	if (mv_isComputer)
		return [self displayName];
	
	if ([self isBootVolume])
		return [self displayName];
	
	return [self path];
}

- (NSString *)kindString;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![[self cache] kind_initialized:&result])
	{
		@synchronized(self) {
			CFStringRef outString=nil;
			
			if ([self FSRefPtr])
			{
				OSStatus err = LSCopyKindStringForRef([self FSRefPtr], &outString);
				
				/* buggy - returns bad info for audio CDs
				OSStatus err = LSCopyItemAttribute([self FSRefPtr],
												   kLSRolesAll,
												   kLSItemDisplayKind, &outString);
				*/
				
				if (!err)
					result = (NSString*)outString;
			}
			
			// Apple returns "Alias" for Symlinks
			if ([self isSymbolicLink])
				result = [NTStringShare symbolicLinkKindString];
			
			if (!result)
				result = @"";
			
			[[self cache] setKind:result];
			
			// release the outString
			if (outString)
				CFRelease(outString);			
		}
	}
	
    return result;
}

- (NSString *)architecture;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![[self cache] architecture_initialized:&result])
	{
		@synchronized(self) {
			NSString *path=nil;
			
			if ([self isApplication] && [self isPackage])
			{
				NSBundle* bundle = [NSBundle bundleWithPath:[self path]];
				path = [bundle executablePath];
			}
			else if ([self isExecutableBitSet])
				path = [self path];
			
			result = @"";
			if (path && [self isReadable])
			{
				@try {
					NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
					NSData *data = [fileHandle readDataOfLength:8];
					[fileHandle closeFile];
					
					// open the executable and look for "feedface" (PowerPC), "cafebabe" (Universal), or "cefaedfe" (Intel)
					if (data)
					{
						if ([data length] > 4)
						{
							unsigned marker;
							[data getBytes:&marker length:4];
							
							// convert from big to native and compare to the big endian constant value
							marker = NSSwapBigIntToHost(marker);
							
							if (marker == 0xfeedface)
								result = @"PowerPC";
							else if (marker == 0xcafebabe)
								result = @"Universal";
							else if (marker == 0xcefaedfe)
								result = @"Intel";
						}
					}
				}
				@catch (NSException * e) {
					NSLog(@"%@", [e description]);
				}
				@finally {
				}
			}
			
			[[self cache] setArchitecture:result];
		}
	}
	
    return result;
}

- (BOOL)isExtensionHidden;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isExtensionHidden_initialized:&result])
	{
		@synchronized(self) {
			if ([self FSRefPtr])
			{
				CFTypeRef outBool;
				OSStatus err = LSCopyItemAttribute([self FSRefPtr],
												   kLSRolesAll,
												   kLSItemExtensionIsHidden, &outBool);
				
				if (!err)
				{
					result = [(NSNumber*) outBool boolValue];
					CFRelease(outBool);
				}
			}
			
			[[self cache] setIsExtensionHidden:result];
		}
	}
	
    return result;
}

- (BOOL)isApplication;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isApplication_initialized:&result])
	{
		@synchronized(self) {
			result = UTTypeConformsTo((CFStringRef) [self uniformTypeID], kUTTypeApplication);
			
			[[self cache] setIsApplication:result];
		}
	}
	
    return result;
}

- (BOOL)isPackage;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![[self cache] isPackage_initialized:&result])
	{
		@synchronized(self) {
			result = UTTypeConformsTo((CFStringRef) [self uniformTypeID], kUTTypePackage);
			
			[[self cache] setIsPackage:result];
		}
	}
	
    return result;
}

- (NTVolume*)volume;
{
    if (!mv_valid || mv_isComputer)
        return nil;

	NTVolume* result=nil;
	if (![[self cache] volume_initialized:&result])
	{
		@synchronized(self) {
			result = [[NTVolumeCache sharedInstance] volumeForRefNum:[self volumeRefNum]];
			
			[[self cache] setVolume:result];
		}
	}
	
    return result;
}

@end

@implementation NTFileDesc (NTVolume)

- (BOOL)isVolumeReadOnly;
{
	return [[self volume] isReadOnly];
}

- (BOOL)isBootVolume;
{
	FSRef *bootRef = [NTFileDesc bootFSRef];
    
    if (bootRef && [self FSRefPtr])
        return (FSCompareFSRefs([self FSRefPtr], bootRef) == noErr);
	
    return NO;
}

- (BOOL)isExternal;
{
	return [[self volume] isExternal];
}

- (BOOL)isNetwork;
{
	return [[self volume] isNetwork];
}

- (BOOL)isLocalFileSystem
{
	return [[self volume] isLocalFileSystem];
}

- (BOOL)isSlowVolume;  // DVD, CD, Network
{
	NTVolume* volume = [self volume];
	
	// making an assumption here, if readOnly, we are assuming a burned disk of some kind
	return ([volume isNetwork] || [volume isReadOnly] || [volume isAudioCD] || [volume isCDROM] || [volume isDVDROM]);
}

- (BOOL)isEjectable;
{
	return [[self volume] isEjectable];
}

- (NTFileDesc *)mountPoint;
{
	return [[self volume] mountPoint];
}

@end

@implementation NTFileDesc (Setters)

- (NSString*)displayNameForRename;
{
	if ([self isVolume])
		return [self displayName];
	
	// use the name, but must display / instead of colons
	return [[self name] stringByReplacing:@":" with:@"/"];
}

- (NSString*)rename:(NSString*)newName err:(OSStatus*)outErr;
{
    NSString* result=nil;
	OSErr err=noErr;

	// convert slashes to colons for the comparison to the old name, we store the posix name
	newName = [newName stringByReplacing:@"/" with:@":"];
	
	// name must be different
	if (![newName isEqualToString:[self name]])
	{	
		// convert back to slashes for this call to succeed
		newName = [newName stringByReplacing:@":" with:@"/"];
		
		unichar buffer[1024];
		FSRef newRef;
		
		[newName getCharacters:buffer];
		
		err = FSRenameUnicode([self FSRefPtr],
							  [newName length],
							  (const UniChar *) buffer,
							  kTextEncodingUnknown,
							  &newRef);
		
		if (!err)
		{
			// could synchronize in updateFSRefObject, but it's called on creation, so might as well do it here instead to avoid that initial synch
			@synchronized(self) {
				// this dumps the case and is basically recreated from scratch which is what we want
				[self updateFSRefObject:[NTFSRefObject refObject:&newRef catalogInfo:nil bitmap:0 name:nil]];
			}
			
			result = [self name];
		}
	}
	
	if (outErr)
		*outErr = err;
	
    return result;
}

@end

