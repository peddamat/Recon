//
//  NTFileDesc-Private.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/13/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NTFileDesc-Private.h"
#import "NTVolume.h"
#import "NTAliasFileManager.h"
#import "NTFileDescData.h"
#import "NTFileDescMemCache.h"
#import "NTResourceMgr.h"
#import "NTFSRefObject.h"
#import "NTMetadata.h"

@implementation NTFileDesc (Private)

- (NSString*)volumeInfoString;
{
	UInt64 freeBytes = [NTFileDesc volumeFreeBytes:self];
	
	UInt64 volumeSize = [NTFileDesc volumeTotalBytes:self];
	UInt64 usedBytes = (volumeSize - freeBytes);
	
	NSString* freeSpace = [[NTSizeFormatter sharedInstance] fileSize:freeBytes];
	NSString* usedSpace = [[NTSizeFormatter sharedInstance] fileSize:usedBytes];
	
	return [NSString stringWithFormat:[NTLocalizedString localize:@"%@, %@ free"], usedSpace, freeSpace];
}	

- (NTFileDesc*)resolvedDesc:(BOOL)resolveIfServerAlias;
{
    if (!mv_valid || mv_isComputer)
        return nil;
		
	NTFileDesc* resolvedDesc=nil;
    @synchronized(self) {
		
		BOOL brokenAlias=NO;
		[[self cache] isBrokenAlias_initialized:&brokenAlias];
		
		BOOL serverAlias=NO;
		[[self cache] isServerAlias_initialized:&serverAlias];
		
		[[self cache] resolvedDesc_initialized:&resolvedDesc];
				
		// did resolved desc go bad?
		if (resolvedDesc && ![resolvedDesc stillExists])
		{
			[[self cache] setResolvedDesc:nil];
			resolvedDesc = nil;
		}
		
		if (!resolvedDesc)
		{
			if ([self isAlias] && (!brokenAlias || (serverAlias && resolveIfServerAlias)))
			{
				BOOL isServerAlias, broken = YES;
				resolvedDesc = [NTFileDesc resolveAlias:self resolveIfServerAlias:resolveIfServerAlias isServerAlias:&isServerAlias];
				
				[[self cache] setIsServerAlias:isServerAlias];

				if (resolvedDesc && [resolvedDesc isValid])
				{
					[resolvedDesc setAliasDesc:self]; // remember the original file
					
					[[self cache] setResolvedDesc:resolvedDesc];
					broken = NO;
				}
				
				[[self cache] setIsBrokenAlias:broken];
			}
		}
    }
	
    return resolvedDesc;
}

- (void)setAliasDesc:(NTFileDesc*)desc;
{
	// we only store the original files path to avoid a double retain problem since the original desc already retains the resolved desc
	[[self cache] setOriginalAliasFilePath:[desc path]];
}

+ (NTFileDesc*)resolveAlias:(NTFileDesc*)desc resolveIfServerAlias:(BOOL)resolveIfServerAlias isServerAlias:(BOOL*)outIsServerAlias;
{
    NTFileDesc* resolvedDesc=nil;
    BOOL isServerAlias=NO;
    
    if ([desc isAlias])
    {
        if (![desc isValid])
            return nil;
		
        if ([desc isSymbolicLink])
        {
			// I think this is the same as readlink()                    
			char resolved[PATH_MAX];
			char* result = realpath([desc fileSystemPath], resolved);
			
			if (result == nil)
				; // NSLog(@"symlink failed: %@", [desc path]);
			else
			{
				NSString* resolvedPath = [NSString stringWithFileSystemRepresentation:result];
				
				resolvedDesc = [self descNoResolve:resolvedPath];
			}
        }
        else if ([desc isCarbonAlias])
            resolvedDesc = [NTAliasFileManager resolveAliasFile:desc resolveServer:resolveIfServerAlias outIsServerAlias:&isServerAlias];
        else if ([desc isPathFinderAlias])
            resolvedDesc = [NTAliasFileManager resolvePathFinderAliasFile:desc resolveServer:resolveIfServerAlias outIsServerAlias:&isServerAlias];
    }
	
    if (outIsServerAlias)
        *outIsServerAlias = isServerAlias;
	
    if ([resolvedDesc isValid])
        return resolvedDesc;
	
    return nil;
}

// old style 'vers' resource version
- (NSString*)carbonVersionString:(BOOL)shortVersion;
{
    NTResourceMgr *mgr = [NTResourceMgr mgrWithDesc:self];
    NSData *versRsrc = [mgr resourceForType:'vers' resID:1];
	
    if (versRsrc)
    {
        VersRec versRecP;
		
        // fill in the structure
        [versRsrc getBytes:&versRecP length:sizeof(VersRec)];
		
        // • Get at the version record so we can extract the short version string
        if (shortVersion)
        {
            UInt8 minor = versRecP.numericVersion.minorAndBugRev; // shares a byte
            UInt8 bugRev = versRecP.numericVersion.minorAndBugRev; // shares a byte
            
            minor = minor >> 4;
            bugRev &= 0x0F;
			
            return [NSString stringWithFormat:@"%d.%d.%d", versRecP.numericVersion.majorRev, minor, bugRev];
        }
        else
            return [NSString stringWithPString:versRecP.shortVersion];
    }
	
    return @"";
}

// in Tiger, .hidden was removed, but there were a few files that were not correctly hidden
// hack that might be removed in future OSes
- (BOOL)isUnixFileThatShouldBeHidden;
{
	static NTFileDesc* mach_desc = nil;
	static NTFileDesc* machsym_desc = nil;
	static NTFileDesc* machkernel_desc = nil;
		
    if (!mach_desc)
		mach_desc = [[NTFileDesc descNoResolve:@"/mach"] retain];
	
    if (!machsym_desc)
		machsym_desc = [[NTFileDesc descNoResolve:@"/mach.sym"] retain];

	if (!machkernel_desc)
		machkernel_desc = [[NTFileDesc descNoResolve:@"/mach_kernel.ctfsys"] retain];

	// trying to make things faster
	if ([self isOnBootVolume] && [self parentIsVolume])
	{
		if ([self isEqualToDesc:mach_desc])
			return YES;
		else if ([self isEqualToDesc:machsym_desc])
			return YES;
		else if ([self isEqualToDesc:machkernel_desc])
			return YES;
	}
	
	return NO;
}

- (void)initializeSizeInfo;
{
	if (YES)  // faster
	{
		// total
		[[self cache] setFileSize:[[self FSRefObject] dataLogicalSize] + [[self FSRefObject] rsrcLogicalSize]];	
		[[self cache] setPhysicalFileSize:[[self FSRefObject] dataPhysicalSize] + [[self FSRefObject] rsrcPhysicalSize]];
		
		// data fork
		[[self cache] setDataForkSize:[[self FSRefObject] dataLogicalSize]];
		[[self cache] setDataForkPhysicalSize:[[self FSRefObject] dataPhysicalSize]];
		
		// rsrc fork
		[[self cache] setRsrcForkSize:[[self FSRefObject] rsrcLogicalSize]];
		[[self cache] setRsrcForkPhysicalSize:[[self FSRefObject] rsrcPhysicalSize]];
	}
	else
	{
		OSErr err;
		CatPositionRec	forkIterator;
		
		SInt64 forkSize=0;
		UInt64 forkPhysicalSize=0;
		
		SInt64 dataForkSize=0;
		UInt64 dataForkPhysicalSize=0;
		SInt64 rsrcForkSize=0;
		UInt64 rsrcForkPhysicalSize=0;
		UInt64 totalSize=0;
		UInt64 totalPhysicalSize=0;
		HFSUniStr255 forkName;
		
		/* Iterate through the forks to get the sizes */
		forkIterator.initialize = 0;
		do
		{
			err = FSIterateForks([self FSRefPtr], &forkIterator, &forkName, &forkSize, &forkPhysicalSize);
			if ( noErr == err )
			{
				totalSize += forkSize;
				totalPhysicalSize += forkPhysicalSize;
				
				// data or rsrc fork?
				if ([[NSString stringWithHFSUniStr255:&forkName] isEqualToString:[NTFileDesc rsrcForkName]])
				{
					rsrcForkSize = forkSize;
					rsrcForkPhysicalSize = forkPhysicalSize;
				}
				else if ([[NSString stringWithHFSUniStr255:&forkName] isEqualToString:[NTFileDesc dataForkName]])
				{
					dataForkSize = forkSize;
					dataForkPhysicalSize = forkPhysicalSize;
				}
				else
					; // some unknown fork
			}
		} while ( noErr == err );
		
		// this error is OK, clear it
		if (err == errFSNoMoreItems)
			err = noErr;
		
		if (!err)
		{
			// total
			[[self cache] setFileSize:totalSize];	
			[[self cache] setPhysicalFileSize:totalPhysicalSize];
			
			// data fork
			[[self cache] setDataForkSize:dataForkSize];
			[[self cache] setDataForkPhysicalSize:dataForkPhysicalSize];
			
			// rsrc fork
			[[self cache] setRsrcForkSize:rsrcForkSize];
			[[self cache] setRsrcForkPhysicalSize:rsrcForkPhysicalSize];
		}
	}
}


@end
