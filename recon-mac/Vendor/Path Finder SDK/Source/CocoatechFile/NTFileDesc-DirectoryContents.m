//
//  NTFileDesc-DirectoryContents.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFileDesc-DirectoryContents.h"
#import "NTFileDesc-Private.h"
#import "NTFileDesc-NTUtilities.h"
#import "NTFileDescData.h"
#import "NTVolumeNotificationMgr.h"
#import "NTFileDescMemCache.h"
#import "NTFSRefObject.h"
#import "NTVolume.h"
#import "NTVolumeMgr.h"
#import <sys/DIR.h>
#include <fts.h>

@interface NTFileDesc (DirectoryContentsPrivate)
- (void)flushCatalogInfoHack;

- (void)scanDirectoryContents;
- (NSMutableArray*)directoryListing:(NTFileDesc*)directory;
- (NSMutableArray*)fts_directoryListing:(NTFileDesc*)directory;
@end

@implementation NTFileDesc (DirectoryContents)

// returns an NSArray of FileDescs
- (NSArray*)directoryContents:(BOOL)visibleOnly resolveIfAlias:(BOOL)resolveIfAlias;
{
	return [[self directoryContents:visibleOnly resolveIfAlias:resolveIfAlias infoBitmap:kDefaultCatalogInfoBitmap] autorelease];
}

// *** caller must release, not autoreleased
- (NSArray*)directoryContents:(BOOL)visibleOnly resolveIfAlias:(BOOL)resolveIfAlias infoBitmap:(FSCatalogInfoBitmap)infoBitmap;
{
    NSArray* result=nil;
	
    if (![self isDirectory])
		return nil;
	
	// empty path returns volumes
	if ([self isComputer])
		result = [[[NTVolumeMgr sharedInstance] volumes] retain];
	else
	{
	    NSMutableArray* mutableResult=nil;
		NTFileDesc *desc;

		// used unix for non hfs disks, Carbon filters out the ._xxxx files
		if (!visibleOnly && ![[self volume] supportsForks])
		{
			[self flushCatalogInfoHack];
			
			// If I use unix to get the ._ files, file attributes aren't flushed correctly
			mutableResult = [[self directoryListing:self] retain];
		}
		else
		{
			OSStatus outStatus;
			FSIterator iterator;

			outStatus = FSOpenIterator( [self FSRefPtr], kFSIterateFlat, &iterator );
			if (outStatus == noErr)
			{
				NTFileDescMem* memCache = [[NTFileDescMemCache sharedInstance] checkout];
				
				FSRef *refArray = [memCache refArray];
				FSCatalogInfo *catalogInfoArray = [memCache catalogInfoArray];
				HFSUniStr255 *nameArray = [memCache nameArray];
				
				do
				{
					ItemCount actualCount;
					
					outStatus = FSGetCatalogInfoBulk( iterator,
													  [memCache capacity],
													  &actualCount,
													  NULL,
													  infoBitmap,
													  catalogInfoArray,
													  refArray,
													  NULL,
													  nameArray);
					
					if (outStatus == noErr || outStatus == errFSNoMoreItems)
					{
						unsigned i;
						
						for( i = 0; i < actualCount; i++ )
						{
							NTFSRefObject* refObject;
							
							refObject = [[NTFSRefObject alloc] initWithRef:&refArray[i] 
															   catalogInfo:&catalogInfoArray[i]
																	bitmap:infoBitmap 
																	  name:[NSString fileNameWithHFSUniStr255:&nameArray[i]]];
							
							desc = [[NTFileDesc alloc] initWithFSRefObject:refObject];
							
							if (!mutableResult)
								mutableResult = [[NSMutableArray alloc] initWithCapacity:actualCount];  // caller must release
							[mutableResult addObject:desc];
							
							[refObject release];
							[desc release];
						}
					}
				} while (outStatus == noErr);
				
				if (outStatus == errFSNoMoreItems)
					outStatus = noErr;
				
				FSCloseIterator(iterator);
				
				[[NTFileDescMemCache sharedInstance] checkin:memCache];
			}
		}
		
		// filter mutableResults
		if ([mutableResult count])
		{
			BOOL isVolume = [self isVolume];
			BOOL isBootVolume = NO;
			
			if (isVolume)
				isBootVolume = [self isBootVolume];
			
			int i, cnt = [mutableResult count];
			BOOL remove;
			NTFileDesc* resolvedDesc;
			
			// removing items, go in reverse
			for (i=cnt-1;i>=0;i--)
			{
				remove = NO;
				
				desc = [mutableResult objectAtIndex:i];
				
				// make sure it's valid
				if (![desc isValid])
					remove = YES;
				
				// resolve aliases
				if (!remove && resolveIfAlias)
				{
					resolvedDesc = [desc descResolveIfAlias];
					
					if (resolvedDesc != desc)
					{
						desc = resolvedDesc;
						[mutableResult replaceObjectAtIndex:i withObject:desc];
					}
				}
				
				// take out /.vol, /dev, /automount on any volumes
				if (!remove && isVolume)
				{
					if ([[desc name] isEqualToString:@".vol"] || [[desc path] hasPrefix:@"/automount"])
						remove = YES;
					else if (isBootVolume && [[desc name] isEqualToString:@"dev"])  // only filter out /dev on boot volume
						remove = YES;
				}
				
				// check visibility
				if (!remove && visibleOnly)
				{
					if ([desc isInvisible])
						remove = YES;
				}
				
				if (remove)
					[mutableResult removeObjectAtIndex:i];
			}
		}
		
		result = mutableResult;
	}
	
	// just to be consistent, nil is no items rather than an empty array
	if (![result count])
	{
		[result release];
		result = nil;
	}
	
	return result;
}

- (BOOL)hasDirectoryContents:(BOOL)visibleOnly;
{
    if (!mv_valid)
        return NO;
	
    // make sure weve been checked
    [self scanDirectoryContents];
	
	BOOL result=NO;
    if (visibleOnly)
		[[self cache] hasVisibleDirectoryContents_initialized:&result];
	else
		[[self cache] hasDirectoryContents_initialized:&result];
	
    return result;
}

// used for delete, we must filter out ._ files that have a matching data file
// visibleOnly=NO, resolveIfAlias=NO
- (NSArray*)directoryContentsForDelete;
{
	NSArray *result = [self directoryContents:NO resolveIfAlias:NO];

	if (![[self volume] supportsForks])
		result = [NTFileDesc stripOutDuplicateDotUnderscoreFiles:result];
		
	return result;
}

@end

@implementation NTFileDesc (DirectoryContentsPrivate)

- (void)scanDirectoryContents;
{
	BOOL result;
	if (![[self cache] hasDirectoryContents_initialized:&result])
	{
		BOOL hasDirectoryContents = NO;
		BOOL hasVisibleDirectoryContents = NO;
		
		if (mv_valid && [self isDirectory])
		{
			// if computer or network or a volume, don't scan, just return true
			// don't want to spin up a disk or scan over a slow network
			if ([self isComputer] || [self isNetwork] || [self isVolume])
			{
				hasDirectoryContents = YES;
				hasVisibleDirectoryContents = YES;
			}
			else
			{
				// short cut - check the valence, if more than 4, assume we have visible items
				UInt32 valence = [self valence];
				if (valence > 4)
				{
					hasDirectoryContents = YES;
					hasVisibleDirectoryContents = YES;							
				}
				else
				{
					OSStatus outStatus;
					FSIterator iterator;
					
					outStatus = FSOpenIterator( [self FSRefPtr], kFSIterateFlat, &iterator );
					if (outStatus == noErr)
					{
						NTFileDescMem* memCache = [[NTFileDescMemCache sharedInstance] checkout];                        
						FSRef *refArray = [memCache refArray];
						FSCatalogInfo *catalogInfoArray = [memCache catalogInfoArray];
						HFSUniStr255 *nameArray = [memCache nameArray];                        
						FSCatalogInfoBitmap bitmap = kDefaultCatalogInfoBitmapForDirectoryScan;
						
						do
						{
							ItemCount actualCount;
							
							outStatus = FSGetCatalogInfoBulk( iterator,
															  [memCache minimumCapacity],
															  &actualCount,
															  NULL,
															  bitmap,
															  catalogInfoArray,
															  refArray,
															  NULL,
															  nameArray);
							
							if (outStatus == noErr || outStatus == errFSNoMoreItems)
							{
								int i;
								NTFileDesc *desc;
								
								for (i = 0; i<actualCount; i++)
								{
									NTFSRefObject* refObject = [[NTFSRefObject alloc] initWithRef:&refArray[i]
																					  catalogInfo:&catalogInfoArray[i] 
																						   bitmap:bitmap
																							 name:[NSString fileNameWithHFSUniStr255:&nameArray[i]]];
									
									desc = [[NTFileDesc alloc] initWithFSRefObject:refObject];
									[refObject release];
									
									if (desc && [desc isValid])
									{
										hasDirectoryContents = YES;
										
										if (![desc isInvisible])
											hasVisibleDirectoryContents = YES;
									}
									[desc release];
									
									// break when both true
									if (hasVisibleDirectoryContents && hasDirectoryContents)
										break;
								}
							}
						} while (outStatus == noErr && !hasVisibleDirectoryContents);
						
						if (outStatus == errFSNoMoreItems)
							outStatus = noErr;
						
						FSCloseIterator(iterator);
						
						[[NTFileDescMemCache sharedInstance] checkin:memCache];
					}
				}
			}
		}
		
		[[self cache] setHasDirectoryContents:hasDirectoryContents];
		[[self cache] setHasVisibleDirectoryContents:hasVisibleDirectoryContents];
	}
}

- (NSMutableArray*)directoryListing:(NTFileDesc*)directory;
{
    NSMutableArray* result = nil;
	NSString* directoryPath = [directory path];
	
	if ([directoryPath length])
	{
		DIR* dirp = opendir([directoryPath fileSystemRepresentation]);
		if (dirp)
		{		
			BOOL dot;
			struct dirent dp;
			int readdirResult;
			struct dirent* dirResult;
			char pathBuffer[PATH_MAX];
			
			if ([directoryPath characterAtIndex:[directoryPath length]-1] != '/')
				directoryPath = [directoryPath stringByAppendingString:@"/"];
			
			[directoryPath getFileSystemRepresentation:pathBuffer maxLength:PATH_MAX-1];
			int dirPathLen = strlen(pathBuffer);
			
			for (;;)
			{
				readdirResult = readdir_r(dirp, &dp, &dirResult);
				
				if (dirResult == nil || readdirResult != 0 || dp.d_namlen == 0)
					break;
				
				dot = NO;
				if (dp.d_name[0] == '.')
				{
					// is it the "." dir?
					if (dp.d_namlen == 1)
						dot = YES;
					
					// is it the ".." dir?
					else if (dp.d_namlen == 2 && dp.d_name[1] == '.')
						dot = YES;
				}
				
				// not interested in . or ..
				if (!dot)
				{
					memcpy(pathBuffer+dirPathLen, dp.d_name, dp.d_namlen);
					
					FSRef fsRef;
					NTFileDesc* desc;
					NTFSRefObject *refObject;
					NTPath* ntPath = [[NTPath alloc] initWithFileSystemPath:pathBuffer length:(dirPathLen + dp.d_namlen)];
					
					// create an fsref from path
					if ([NTFSRefObject createFSRef:&fsRef fromPath:[ntPath UTF8Path] followSymlink:NO])
					{						
						refObject = [[NTFSRefObject alloc] initWithRef:&fsRef catalogInfo:nil bitmap:0 name:[ntPath name]];
						
						// update the standard bits to speed things up
						[refObject updateCatalogInfo:kDefaultCatalogInfoBitmap];
						
						desc = [[NTFileDesc alloc] initWithFSRefObject:refObject];
						[refObject release];
						
						if ([desc isValid])
						{
							if (!result)
								result = [NSMutableArray arrayWithCapacity:100];
														
							[result addObject:desc];
						}
						
						[desc release];
					}
					
					[ntPath release];
				}
			}
			
			closedir(dirp);
		}
	}
	
    return result;
}

- (NSMutableArray*)fts_directoryListing:(NTFileDesc*)directory;
{
	NSMutableArray* result = nil;
	
	NSString* directoryPath = [directory path];
	if ([directoryPath length])
	{		
		FTSENT * ftsent;
		char * tPath[2]={(char *)[directory fileSystemPath],NULL};
		BOOL done=NO;
		
		FTS * ftsp = fts_open(tPath, FTS_PHYSICAL | FTS_NOSTAT, 0);
		if (ftsp)
		{
			char pathBuffer[PATH_MAX];
			
			if ([directoryPath characterAtIndex:[directoryPath length]-1] != '/')
				directoryPath = [directoryPath stringByAppendingString:@"/"];
			
			[directoryPath getFileSystemRepresentation:pathBuffer maxLength:PATH_MAX-1];
			int dirPathLen = strlen(pathBuffer);
			
			ftsent = fts_read(ftsp);
			ftsent = fts_children(ftsp, 0);
			
			while (!done && (ftsent != NULL))
			{
				memcpy(pathBuffer+dirPathLen, ftsent->fts_name, ftsent->fts_namelen);
				
				FSRef fsRef;
				NTFileDesc* desc;
				NTFSRefObject *refObject;
				NTPath* ntPath = [[NTPath alloc] initWithFileSystemPath:pathBuffer length:(dirPathLen + ftsent->fts_namelen)];
				
				// create an fsref from path
				if ([NTFSRefObject createFSRef:&fsRef fromPath:[ntPath UTF8Path] followSymlink:NO])
				{						
					refObject = [[NTFSRefObject alloc] initWithRef:&fsRef catalogInfo:nil bitmap:0 name:[ntPath name]];
					desc = [[NTFileDesc alloc] initWithFSRefObject:refObject];
					[refObject release];
					
					if ([desc isValid])
					{
						if (!result)
							result = [NSMutableArray arrayWithCapacity:100];
						
						[result addObject:desc];
					}
					
					[desc release];
				}
				
				[ntPath release];
				
				ftsent = ftsent->fts_link;
			}
			
			int unixErr = fts_close(ftsp);
			if (unixErr != 0)
				NSLog(@"fts_close: %d", unixErr);
		}
	}
	
	return result;
}

// try setting a label on a UFS disk, it doesn't update unless you do this
// OS BUG BUG BUG BUG BUG
- (void)flushCatalogInfoHack;
{
	OSStatus outStatus;
	FSIterator iterator;
	
	outStatus = FSOpenIterator( [self FSRefPtr], kFSIterateFlat, &iterator );
	if (outStatus == noErr)
	{
		ItemCount actualCount;
		outStatus = FSGetCatalogInfoBulk( iterator,
										  1,
										  &actualCount,
										  NULL,
										  kFSCatInfoNone,
										  NULL,
										  NULL,
										  NULL,
										  NULL);
		
		FSCloseIterator(iterator);
	}
}

@end

