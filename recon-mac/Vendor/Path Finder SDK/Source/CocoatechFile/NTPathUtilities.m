//
//  NTPathUtilities.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/10/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTPathUtilities.h"
#include <unistd.h>
#include <sys/stat.h>
#import "NTDefaultDirectory.h"

@implementation NTPathUtilities

+ (BOOL)pathOK:(NSString*)path
{	
	// nil is not valid
	if (!path)
		return NO;
	
    // an empty string is a valid path to all mounted media
    if ([path length] == 0)
        return YES;
	
	return (access([path fileSystemRepresentation], F_OK) == 0);
}

// compares two HFSUniStr255 for equality
// return true if they are identical, false if not
+ (BOOL)compareHFSUniStr255:(const HFSUniStr255 *)lhs
						rhs:(const HFSUniStr255 *)rhs;
{
    return (lhs->length == rhs->length) && (memcmp(lhs->unicode, rhs->unicode, lhs->length * sizeof(UniChar)) == 0);
}

+ (NSString*)pathFromRef:(const FSRef*)ref
{
    UInt8 buffer[PATH_MAX];
    FSRefMakePath(ref, buffer, PATH_MAX);
	
    return [NSString stringWithUTF8String:(char*)buffer];
}

+ (NSString*)fullPathForApplication:(NSString*)appName;
{
    // some people complained that [[NSWorkspace sharedWorkspace] fullPathForApplication:appName] was super slow - not sure why, but for now just do a cheesy check
    if ([appName isEqualToString:kFinderApplicationName])
        return [[NSWorkspace sharedWorkspace] fullPathForApplication:appName];
    else
    {
        NSString *appPath;
        
        // this simple check is pretty lame, but this is just a convienience for the user anyway
        appPath = [[[NTDefaultDirectory sharedInstance] applicationsPath] stringByAppendingPathComponent:appName];
        if ([NTPathUtilities pathOK:appPath])
            return appPath;
		
        appPath = [[[NTDefaultDirectory sharedInstance] developerApplicationsPath] stringByAppendingPathComponent:appName];
        if ([NTPathUtilities pathOK:appPath])
            return appPath;
        
		appPath = [[[NTDefaultDirectory sharedInstance] userApplicationsPath] stringByAppendingPathComponent:appName];
        if ([NTPathUtilities pathOK:appPath])
            return appPath;
		
        appPath = [[[NTDefaultDirectory sharedInstance] networkApplicationsPath] stringByAppendingPathComponent:appName];
        if ([NTPathUtilities pathOK:appPath])
            return appPath;
    }
    
	return [[NSWorkspace sharedWorkspace] fullPathForApplication:appName];
}

@end

@implementation NSString (FSRefUtilities)

+ (NSString *)stringWithFSRef:(const FSRef *)aFSRef
{
    UInt8 thePath[PATH_MAX + 1];		// plus 1 for \0 terminator
	
    return (FSRefMakePath(aFSRef, thePath, PATH_MAX ) == noErr) ? [NSString stringWithUTF8String:(const char *)thePath] : nil;
}

- (BOOL)getFSRef:(FSRef *)aFSRef
{
    UInt8* charPtr = (UInt8*)[self UTF8String];
	
    if (charPtr)
        return FSPathMakeRef(charPtr, aFSRef, NULL) == noErr;
	
    return NO;
}

- (NSString *)resolveAliasFile
{
    FSRef theRef;
    Boolean theIsTargetFolder, theWasAliased;
    NSString * theResolvedAlias = nil;;
	
    [self getFSRef:&theRef];
	
    if ((FSResolveAliasFile( &theRef, YES, &theIsTargetFolder, &theWasAliased ) == noErr))
        theResolvedAlias = (theWasAliased) ? [NSString stringWithFSRef:&theRef] : self;
	
    return theResolvedAlias;
}

@end


/*****************************************************************************/
// extracted from morefilesX

/* macro for casting away const when you really have to */
#define CONST_CAST(type, const_var) (*(type*)((void *)&(const_var)))

OSErr
FSSetHasCustomIcon(
				   const FSRef *ref)
{
	return ( FSChangeFinderFlags(ref, true, kHasCustomIcon) );
}

OSErr
FSClearHasCustomIcon(
					 const FSRef *ref)
{
	return ( FSChangeFinderFlags(ref, false, kHasCustomIcon) );
}

OSErr
FSSetInvisible(
			   const FSRef *ref)
{
	return ( FSChangeFinderFlags(ref, true, kIsInvisible) );
}

OSErr
FSClearInvisible(
				 const FSRef *ref)
{
	return ( FSChangeFinderFlags(ref, false, kIsInvisible) );
}

OSErr
FSChangeFinderFlags(
					const FSRef *ref,
					Boolean setBits,
					UInt16 flagBits)
{
	OSErr			result;
	FSCatalogInfo	catalogInfo;
	FSRef			parentRef;
	
	/* get the current finderInfo */
	result = FSGetCatalogInfo(ref, kFSCatInfoFinderInfo, &catalogInfo, NULL, NULL, &parentRef);
	require_noerr(result, FSGetCatalogInfo);
	
	/* set or clear the appropriate bits in the finderInfo.finderFlags */
	if ( setBits )
	{
		/* OR in the bits */
		((FileInfo *)&catalogInfo.finderInfo)->finderFlags |= flagBits;
	}
	else
	{
		/* AND out the bits */
		((FileInfo *)&catalogInfo.finderInfo)->finderFlags &= ~flagBits;
	}
	
	/* save the modified finderInfo */
	result = FSSetCatalogInfo(ref, kFSCatInfoFinderInfo, &catalogInfo);
	require_noerr(result, FSSetCatalogInfo);
	
FSSetCatalogInfo:
FSGetCatalogInfo:
		
		return ( result );
}

OSStatus FSMakeFSRef(FSVolumeRefNum volRefNum,
			SInt32 dirID,
			NSString* fileName,
			FSRef *outRef)
{
	FSRef parentRef;
	OSStatus err = FSResolveNodeID(volRefNum, dirID, &parentRef);
	
	if (!err)
	{		
		// convert any colons to /
		fileName = [fileName colonToSlash];
		
		int length = [fileName length];
		unichar* buffer;
		FSRef fileRef;
		
		buffer = malloc(sizeof(unichar) * length);
		[fileName getCharacters:buffer];
		
		err = FSMakeFSRefUnicode (&parentRef,
								  length,
								  buffer,
								  kTextEncodingUnknown,  // is this OK?
								  &fileRef);
		
		free(buffer);
		
		if (!err)
			*outRef = fileRef;
	}
	
	if (err)
		NSLog(@"FSMakeFSRef error: %d", err);
	
	return err;
}

