//
//  NTFileModifier.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/10/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTFileModifier.h"
#import "NTCarbonFileInfo.h"
#import <unistd.h>
#include <sys/stat.h>

@implementation NTFileModifier

+ (BOOL)setPermissions:(unsigned long)permissions desc:(NTFileDesc*)desc;
{
    // use the Authentication stuff if not the owner of the file
    BOOL result=NO;
    BOOL needPermission;
	
    // if we are root, we don't need permission
    needPermission = ![[NTUsersAndGroups sharedInstance] isRoot];
	
    // do we own this file?  chmod requires that we own the file or be root
    if (needPermission)
    {
        if ([desc ownerID] == [[NTUsersAndGroups sharedInstance] userID])
            needPermission = NO;
    }
	
    // if I'm not the owner, get root permission
    if (needPermission)
		NSLog(@"-[%@ %@] needPermission", [self className], NSStringFromSelector(_cmd));
    else
        result = (chmod([desc fileSystemPath], permissions) == 0);
	
    return result;
}

+ (BOOL)setType:(OSType)type desc:(NTFileDesc*)desc;
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
    [attributes setObject:[NSNumber numberWithInt:type] forKey:NSFileHFSTypeCode];
    return [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:[desc path] error:nil];
}

+ (BOOL)setCreator:(OSType)creator desc:(NTFileDesc*)desc;
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
    [attributes setObject:[NSNumber numberWithInt:creator] forKey:NSFileHFSCreatorCode];
    return [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:[desc path] error:nil];
}

// labels are 0 for none and 1-7 for colors
+ (BOOL)setLabel:(int)label desc:(NTFileDesc*)desc;
{
    NTCarbonFileInfo* cFileInfo = [[[NTCarbonFileInfo alloc] initWithDesc:desc] autorelease];
	
    if ([cFileInfo fileInfo])
    {
        FileInfo fileInfo = *[cFileInfo fileInfo];
		
        if (label >= 0 && label <= 7)
        {
            UInt16 newLabel = label;
			
            newLabel = (newLabel << 1);
			
            fileInfo.finderFlags &= ~kColor;
            fileInfo.finderFlags |= (newLabel & kColor);
			
            [cFileInfo setFileInfo:&fileInfo];
        }
		
        return YES;
    }
	
    return NO;
}

+ (BOOL)setFileInfo:(FileInfo*)fileInfo desc:(NTFileDesc*)desc;
{
    NTCarbonFileInfo* cFileInfo = [[[NTCarbonFileInfo alloc] initWithDesc:desc] autorelease];
	
    [cFileInfo setFileInfo:fileInfo];
	
    return YES;
}

+ (BOOL)setInvisible:(BOOL)set desc:(NTFileDesc*)desc;
{
    NTCarbonFileInfo* cFileInfo = [[[NTCarbonFileInfo alloc] initWithDesc:desc] autorelease];
	
    if ([cFileInfo fileInfo])
    {
        FileInfo fileInfo;
		
        fileInfo = *[cFileInfo fileInfo];
		
        if (set)
            fileInfo.finderFlags |= kIsInvisible;
        else
            fileInfo.finderFlags &= ~kIsInvisible;
		
        [cFileInfo setFileInfo:&fileInfo];
		
        return YES;
    }
	
    return NO;
}

+ (BOOL)setLength:(unsigned int)length desc:(NTFileDesc*)desc;
{
    int result = truncate([desc fileSystemPath], length);
	
    return (result == 0);
}

+ (BOOL)setExtensionHidden:(BOOL)set desc:(NTFileDesc*)desc;
{	
	OSStatus err = LSSetExtensionHiddenForRef([desc FSRefPtr], set);
	
	return (err == noErr);
}

+ (BOOL)setLock:(BOOL)set desc:(NTFileDesc*)desc;
{
    FSCatalogInfo catalogInfo;
    OSStatus err;
	
    if ([desc FSRefPtr])
    {
        err = FSGetCatalogInfo([desc FSRefPtr], kFSCatInfoNodeFlags, &catalogInfo, NULL, NULL, NULL);
        if (err == noErr)
        {
            if (set)
                catalogInfo.nodeFlags |= kFSNodeLockedMask;
            else
                catalogInfo.nodeFlags &= ~kFSNodeLockedMask;
			
            err = FSSetCatalogInfo([desc FSRefPtr], kFSCatInfoNodeFlags, &catalogInfo);
        }
		
        return (err == noErr);
    }
	
    return NO;
}

+ (BOOL)setStationery:(BOOL)set desc:(NTFileDesc*)desc;
{
    NTCarbonFileInfo* cFileInfo = [[[NTCarbonFileInfo alloc] initWithDesc:desc] autorelease];
	
    if ([cFileInfo fileInfo])
    {
        FileInfo fileInfo;
		
        fileInfo = *[cFileInfo fileInfo];
		
        if (set)
            fileInfo.finderFlags |= kIsStationery;
        else
            fileInfo.finderFlags &= ~kIsStationery;
		
        [cFileInfo setFileInfo:&fileInfo];
		
        return YES;
    }
	
    return NO;
}

+ (BOOL)setHasBundle:(BOOL)set desc:(NTFileDesc*)desc;
{
    // bundle bit!  Used for folders to indicate a package
    NTCarbonFileInfo* cFileInfo = [[[NTCarbonFileInfo alloc] initWithDesc:desc] autorelease];
    
    if ([cFileInfo fileInfo])
    {
        FileInfo fileInfo;
        
        fileInfo = *[cFileInfo fileInfo];
        
        if (set)
            fileInfo.finderFlags |= kHasBundle;
        else
            fileInfo.finderFlags &= ~kHasBundle;
        
        [cFileInfo setFileInfo:&fileInfo];
        
        return YES;
    }
    
    return NO;
}

// sets the alias finder flag
+ (BOOL)setAlias:(BOOL)set desc:(NTFileDesc*)desc;
{
    // bundle bit!  Used for folders to indicate a package
    NTCarbonFileInfo* cFileInfo = [[[NTCarbonFileInfo alloc] initWithDesc:desc] autorelease];
    
    if ([cFileInfo fileInfo])
    {
        FileInfo fileInfo;
        
        fileInfo = *[cFileInfo fileInfo];
        
        if (set)
            fileInfo.finderFlags |= kIsAlias;
        else
            fileInfo.finderFlags &= ~kIsAlias;
        
        [cFileInfo setFileInfo:&fileInfo];
        
        return YES;
    }
    
    return NO;
}

+ (BOOL)setFinderPosition:(NSPoint)point desc:(NTFileDesc*)desc;
{
    NTCarbonFileInfo* cFileInfo = [[[NTCarbonFileInfo alloc] initWithDesc:desc] autorelease];
	
    if ([cFileInfo fileInfo])
    {
        FileInfo fileInfo;
        Point carbonPoint;
        
        fileInfo = *[cFileInfo fileInfo];
		
        carbonPoint.h = (short) point.x;
        carbonPoint.v = (short) point.y;
        
        fileInfo.location = carbonPoint;
		
        [cFileInfo setFileInfo:&fileInfo];
		
        return YES;
    }
	
    return NO;
}

@end
