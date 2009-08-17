//
//  NTFileDesc-NTUtilities.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/13/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NTFileDesc-NTUtilities.h"
#import <sys/stat.h>
#import <sys/fcntl.h>
#import "NTDefaultDirectory.h"
#import "NTAlias.h"
#import "NTFileDesc-Private.h"
#import "NTFSRefObject.h"
#import "NTIcon.h"
#import <unistd.h>
#import "NTWeblocFile.h"
#import "NTVolume.h"
#import "NTPathUtilities.h"
#import "NSImage-CocoatechFile.h"

@implementation NTFileDesc (NTUtilities)

+ (NTFileDesc*)descResolve:(NSString*)path;
{
    NTFileDesc* result = nil;
	
	if (path)
	{
		result = [[[self alloc] initWithPath:path] autorelease];
	
		NTFileDesc* resolved = [result resolvedDesc:NO];
		if (resolved)
			result = resolved;
	}
	
    return result;
}

+ (NTFileDesc*)descNoResolve:(NSString*)path;
{
    NTFileDesc* result = nil;
	
	if (path)
		result = [[[self alloc] initWithPath:path] autorelease];
	
    return result;
}

+ (NTFileDesc*)descResolveServerAlias:(NSString*)path;
{
    NTFileDesc* result = nil;
	
	if (path)
	{
		result = [[[self alloc] initWithPath:path] autorelease];
		
		NTFileDesc* resolved = [result resolvedDesc:YES];
		if (resolved)
			result = resolved;
	}
	
    return result;
}

+ (NTFileDesc*)descFSRef:(const FSRef*)ref;
{
    return [self descFSRefObject:[NTFSRefObject refObject:ref catalogInfo:nil bitmap:0 name:nil]];
}

+ (NTFileDesc*)descFSRefObject:(NTFSRefObject*)refObject;
{
    NTFileDesc* result = [[self alloc] initWithFSRefObject:refObject];
	
    return [result autorelease];
}

+ (NTFileDesc*)descVolumeRefNum:(FSVolumeRefNum)vRefNum;
{
    OSStatus err;
    FSRef volRef;
	
    err = FSGetVolumeInfo(vRefNum, 0, NULL, kFSVolInfoNone, NULL, NULL, &volRef);
	
    if (err == noErr)
    {
        NTFileDesc* result = [self descFSRef:&volRef];
		
        return result;
    }
	
    return nil;
}

// create an invalid result for functions - is this used anywhere?
+ (NTFileDesc*)inValid
{
    NTFileDesc* result = [[[self alloc] initWithPath:@""] autorelease];
	
    // set to invalid
    result->mv_valid = NO;
	
    return result;
}

// could be slow, call from thread
+ (UInt64)volumeTotalBytes:(NTFileDesc*)inDesc;
{
    if ([inDesc isValid])
    {
        if ([inDesc isComputer])
            return [NTVolume totalBytes_everyVolume];
        else
            return [[inDesc volume] totalBytes];
    }
    
    return 0;
}

// could be slow, call from thread
+ (UInt64)volumeFreeBytes:(NTFileDesc*)inDesc;
{
    if ([inDesc isValid])
    {
        if ([inDesc isComputer])
            return [NTVolume freeBytes_everyVolume];
        else
			return [[inDesc volume] freeBytes];
    }

    return 0;    
}

+ (NSMutableArray*)descsToPaths:(NSArray*)descs;
{
    NSMutableArray* paths = [NSMutableArray arrayWithCapacity:[descs count]];
    NTFileDesc* desc;
	
    for (desc in descs)
    {
        NSString* path = [desc path];
		
        if (path)
            [paths addObject:path];
    }
	
    if ([paths count])
        return paths;
	
    return nil;
}

+ (NSArray*)foldersForDescs:(NSArray*)descs;
{
	NSMutableArray* folders = [NSMutableArray arrayWithCapacity:[descs count]];
    NTFileDesc* desc;
	
    for (desc in descs)
    {
		if ([desc isFile])
			desc = [desc parentDesc];
		
        if (desc)
            [folders addObject:desc];
    }
	
    if ([folders count])
        return folders;
	
    return nil;	
}

+ (NSMutableArray*)descsToFilesAndFolders:(NSArray*)theDescs
							   outFolders:(NSMutableArray**)outFolders
				   treatPackagesAsFolders:(BOOL)treatPackagesAsFolders;
{
	NSMutableArray* folders = [[[NSMutableArray alloc] initWithCapacity:20] autorelease];
	NSMutableArray* files = [[[NSMutableArray alloc] initWithCapacity:20] autorelease];
	
	for (NTFileDesc *itemDesc in theDescs)
	{
		BOOL isFile = [itemDesc isFile];
		
		if (!isFile && !treatPackagesAsFolders)
		{
			if ([itemDesc isPackage])
				isFile = YES;
		}
		
		if (isFile)
			[files addObject:itemDesc];
		else
			[folders addObject:itemDesc];
	}	
	
	if (outFolders)
		*outFolders = folders;
	
	return files;
}

+ (NSMutableArray*)descsToURLs:(NSArray*)descs;
{
	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[descs count]];
    NTFileDesc* desc;
	
    for (desc in descs)
    {
        NSURL* url = [desc URL];
		
        if (url)
            [result addObject:url];
    }
	
    if ([result count])
        return result;
	
    return nil;	
}

+ (NSMutableArray*)descsToNames:(NSArray*)descs;
{
    NSMutableArray* names = [NSMutableArray arrayWithCapacity:[descs count]];
    NTFileDesc* desc;
	
    for (desc in descs)
    {
		// nameWhenCreated cached and fast
        NSString* name = [desc nameWhenCreated];
		
        if (name)
            [names addObject:name];
    }
	
    if ([names count])
        return names;
	
    return nil;
}

+ (NSMutableArray*)newDescs:(NSArray*)descs;
{
	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[descs count]];
    NTFileDesc* desc;
	
    for (desc in descs)
	{
		desc = [desc newDesc];
		
		if (desc)
			[result addObject:desc];
	}
	
    if ([result count])
        return result;
	
    return nil;	
}

+ (NSMutableArray*)descsStillExist:(NSArray*)descs;
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[descs count]];
    NTFileDesc* desc;
	
    for (desc in descs)
	{		
		if ([desc stillExists])
			[result addObject:desc];
	}
	
    if ([result count])
        return result;
	
    return nil;
}

+ (NSMutableArray*)descsToAliases:(NSArray*)descs;
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[descs count]];
    NTFileDesc* desc;
	NTAlias *alias;
	
    for (desc in descs)
	{
		alias = [NTAlias aliasWithDesc:desc];
		
		if (alias)
			[result addObject:alias];
	}
	
    if ([result count])
        return result;
	
    return nil;
}

+ (NSMutableArray*)aliasesToDescs:(NSArray*)aliases;
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[aliases count]];
    NTFileDesc* desc;
	NTAlias *alias;
	
    for (alias in aliases)
	{
		desc = [alias desc];
		
		if (desc)
			[result addObject:desc];
	}
	
    if ([result count])
        return result;
	
    return nil;
}

+ (NSMutableArray*)pathsToDescs:(NSArray*)paths;
{
    NSMutableArray* descs = [NSMutableArray arrayWithCapacity:[paths count]];
    NSString* path;
	
    for (path in paths)
    {
        NTFileDesc* desc = [[self alloc] initWithPath:path];
				
        if (desc && [desc isValid])
            [descs addObject:desc];
		
		[desc release];
    }
	
    if ([descs count])
        return descs;
	
    return nil;    
}

+ (NSMutableArray*)urlsToDescs:(NSArray*)urls;
{
    NSMutableArray* descs = [NSMutableArray arrayWithCapacity:[urls count]];
    NSURL* url;
	
    for (url in urls)
    {
        NTFileDesc* desc = [[self alloc] initWithPath:[url path]];
		
        if (desc && [desc isValid])
            [descs addObject:desc];
		
		[desc release];
    }
	
    if ([descs count])
        return descs;
	
    return nil;    
}

+ (NSMutableArray*)badURLs:(NSArray*)urls;
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[urls count]];
    NSURL* url;
	
    for (url in urls)
    {
        NTFileDesc* desc = [[self alloc] initWithPath:[url path]];
		
        if (desc && [desc isValid])
            ;
		else
			[result addObject:url];
		
		[desc release];
    }
	
    if ([result count])
        return result;
	
    return nil;    
}

+ (NSMutableArray*)urlsToPaths:(NSArray*)urls;
{
    NSMutableArray* paths = [NSMutableArray arrayWithCapacity:[urls count]];
    NSURL* url;
	
    for (url in urls)
    {
		NSString * path = [url path];
		
        if (path)
            [paths addObject:path];
    }
	
    if ([paths count])
        return paths;
	
    return nil;    
}

+ (NSMutableArray*)pathsToURLs:(NSArray*)paths;
{
    NSMutableArray* urls = [NSMutableArray arrayWithCapacity:[paths count]];
    NSString* path;
	
    for (path in paths)
    {
		NSString *url = [NSURL fileURLWithPath:path];
		
        if (url)
            [urls addObject:url];
    }
	
    if ([urls count])
        return urls;
	
    return nil;    
}

+ (NSMutableArray*)standardizePaths:(NSArray*)inPaths;
{
    NSMutableArray* paths = [NSMutableArray arrayWithCapacity:[inPaths count]];
    NSString * path;
	NSString* newPath;
	
    for (path in inPaths)
    {
		newPath = [path stringByResolvingSymlinksInPath];
		if (!newPath)
			newPath = path;
		
        if (newPath)
            [paths addObject:newPath];
    }
	
    if ([paths count])
        return paths;
	
    return nil;    
}

+ (NSArray*)expandedPaths:(NSArray*)inPaths;
{
	NSMutableArray* paths = [NSMutableArray arrayWithCapacity:[inPaths count]];
    NSString * path;
	NSString* newPath;
	
    for (path in inPaths)
    {
		newPath = [path stringByExpandingTildeInPath];
		
        if (newPath)
            [paths addObject:newPath];
    }
	
    if ([paths count])
        return paths;
	
    return nil;    
}

+ (NSArray*)arrayByRecreatingDescs:(NSArray*)inDescs;
{
	NSMutableArray* descs = [NSMutableArray array];
    NTFileDesc *desc;
	
    for (desc in inDescs)
    {		
		desc = [[self alloc] initWithPath:[desc path]];
				
        if (desc && [desc isValid])
            [descs addObject:desc];
		
		[desc release];
    }
	
    if ([descs count])
        return descs;
	
    return nil;    
}

+ (NSArray*)arrayByResolvingAliases:(NSArray*)inDescs;
{
	NSMutableArray* descs = [NSMutableArray array];
    NTFileDesc *desc;
	
    for (desc in inDescs)
    {		
		desc = [desc descResolveIfAlias:NO];
		
        if (desc && [desc isValid])
            [descs addObject:desc];
    }
	
    if ([descs count])
        return descs;
	
    return nil;    
}

+ (NTFileDesc*)applicationForExtension:(NSString*)extension;
{
    FSRef outAppRef;
    NSString* path = [@"test" stringByAppendingPathExtension:extension];
    NTFileDesc* desc;
    
    path = [[[NTDefaultDirectory sharedInstance] tmpPath] stringByAppendingPathComponent:path];
    desc = [self descNoResolve:path];
    if (!desc || ![desc isValid])
    {
        // create file 
        int fd = open([path fileSystemRepresentation], O_CREAT | O_TRUNC | O_WRONLY, 0644);        
        if (fd != -1)
        {
            close(fd);  // need to close the file
            desc = [self descNoResolve:path];
        }
    }
    
    if (desc && [desc isValid])
    {
        OSStatus err = LSGetApplicationForItem([desc FSRefPtr], kLSRolesAll, &outAppRef, NULL);
        
        if (!err)
        {
            NTFileDesc* result = [self descFSRef:&outAppRef];
            
            if ([result isValid])
                return result;
        }
    }
    
    return nil;
}

// returns "Document" for extensions it does not recognize
+ (NSString*)kindStringForExtension:(NSString*)extension;
{
    CFStringRef outKindString;
    
    OSStatus err = LSCopyKindStringForTypeInfo(kLSUnknownType, kLSUnknownCreator, (CFStringRef)extension, &outKindString);
    if (!err)
    {
        NSString *result = [NSString stringWithString:(NSString*)outKindString];
        CFRelease(outKindString);
        
        return result;
    }
    
    return nil;
}

+ (NTFileDesc*)applicationForType:(OSType)type creator:(OSType)creator extension:(NSString*)extension;
{
    NTFileDesc* result=nil;
    CFURLRef outAppURL;
    
    OSStatus err = LSGetApplicationForInfo(type, creator, (CFStringRef)extension, kLSRolesAll, NULL, &outAppURL);
    if (!err)
    {
        NSString* path = [[[(NSURL*)outAppURL path] retain] autorelease];
        CFRelease(outAppURL);
        
        result = [self descResolve:path];
    }
    
    return result;
}

+ (NSArray*)parentFoldersForDescs:(NSArray*)descs;
{
	NSMutableDictionary* result = [NSMutableDictionary dictionary];
	
	NTFileDesc* desc, *parentDesc;
	
	for (desc in descs)
	{
		parentDesc = [desc parentDesc];
		if (parentDesc)
		{
			// removes duplicates
			[result setObject:parentDesc forKey:[parentDesc dictionaryKey]];
		}
	}
	
	return [result allValues];
}

+ (NSMutableArray*)descsNoDuplicates:(NSArray*)descs;
{
	NSMutableDictionary* result = [NSMutableDictionary dictionary];
	
	NTFileDesc* desc;
	
	for (desc in descs)
	{
		// removes duplicates
		[result setObject:desc forKey:[desc dictionaryKey]];
	}
	
	return [NSMutableArray arrayWithArray:[result allValues]];
}

+ (NSArray*)removeDescsWithParentInList:(NSArray*)srcDescs;
{
    NSMutableArray* folders = [NSMutableArray array];
    NTFileDesc* desc;
    
    // first get the folders in the list
    for (desc in srcDescs)
    {
        if ([desc isDirectory])
            [folders addObject:desc];
    }
    
    if ([folders count])
    {
        NSMutableArray* result = [NSMutableArray array];
        
        for (desc in srcDescs)
        {
            NSEnumerator* folderEnumerator = [folders objectEnumerator];
            NTFileDesc* folderDesc;
            BOOL addItem = YES;
            
            while (folderDesc = [folderEnumerator nextObject])
            {
                if ([folderDesc isParentOfDesc:desc])
                {
                    addItem = NO;
                    break;
                }
            }                
            
            if (addItem)
                [result addObject:desc];
        }
        
        return result;
    }
    
    return srcDescs;
}

+ (NTFileDesc*)bootVolumeDesc;
{
	static NTFileDesc* shared = nil;
	
    if (!shared)
	{
		// avoid allocating two or more in threads
		@synchronized(self) {
			if (!shared)
				shared = [[self descFSRef:[self bootFSRef]] retain];
		}
	}
	
	return shared;
}

+ (FSRef*)bootFSRef;
{
    return [NTFSRefObject bootFSRef];
}

+ (BOOL)isNetworkURLDesc:(NTFileDesc*)desc;
{
	BOOL acceptsFile = NO;
	
	if (desc)
	{		
		if ([NTWeblocFile isServerWeblocFile:desc])
		{
			NSURL *url = [NTWeblocFile urlFromWeblocFile:desc];
			
			if (url)
				acceptsFile = YES;
		}
	}			
	
	return acceptsFile;
}

- (NSMenu*)pathMenu:(SEL)action target:(id)target;
{
	return [self pathMenu:action target:target fontSize:kDefaultMenuFontSize];
}

- (NSMenu*)pathMenu:(SEL)action target:(id)target fontSize:(int)fontSize;
{
	NSMenu *result = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	NSMenuItem *menuItem;
	
	NSArray* pathComponents = [self pathComponents:YES];
	NTFileDesc* desc;
	NSEnumerator *enumerator = [pathComponents reverseObjectEnumerator];
	
	// skip first item
	[enumerator nextObject];

	// build in reverse order
	while (desc = [enumerator nextObject])
	{		
		menuItem = [[[NSMenuItem alloc] initWithTitle:[desc displayName] action:action keyEquivalent: @""] autorelease];
		
		[menuItem setRepresentedObject:[desc path]];		
		[menuItem setImage:[NSImage iconRef:[[desc icon] iconRef] toImage:(fontSize == kSmallMenuFontSize) ? kSmallMenuIconSize : kDefaultMenuIconSize]];
		[menuItem setTarget:target];
		[menuItem setFontSize:fontSize color:nil];

		[result addItem:menuItem];
	}
	
	// must add computer at end
	desc = [[NTDefaultDirectory sharedInstance] computer];
	menuItem = [[[NSMenuItem alloc] initWithTitle:[desc displayName] action:action keyEquivalent: @""] autorelease];
	
	[menuItem setRepresentedObject:[desc path]];
	[menuItem setImage:[NSImage iconRef:[[desc icon] iconRef] toImage:(fontSize == kSmallMenuFontSize) ? kSmallMenuIconSize : kDefaultMenuIconSize]];
	
	[menuItem setTarget:target];
	[menuItem setFontSize:fontSize color:nil];
	[result addItem:menuItem];        
	
	return result;
}

+ (NSString*)dataForkName;
{
	static NSString* shared=nil;
	
	if (!shared)
	{
		HFSUniStr255 forkName;
		OSErr err;
		
		err = FSGetDataForkName(&forkName);
		
		if (!err)
			shared = [[NSString stringWithHFSUniStr255:&forkName] retain];
	}
	
	return shared;
}

+ (NSString*)rsrcForkName;
{
	static NSString* shared=nil;
	
	if (!shared)
	{
		HFSUniStr255 forkName;
		OSErr err;
		
		err = FSGetResourceForkName(&forkName);
		
		if (!err)
			shared = [[NSString stringWithHFSUniStr255:&forkName] retain];
	}
	
	return shared;
}

+ (NTFileDesc*)mainBundleDesc;
{
	static NTFileDesc* shared=nil;
	
	if (!shared)
		shared = [[NTFileDesc descResolve:[[NSBundle mainBundle] bundlePath]] retain];
	
	return shared;
}

+ (NSArray*)stripOutDuplicateDotUnderscoreFiles:(NSArray*)descs;
{	
	// must must remove ._ files from our list that have a corresponding data file, otherwise we get errors
	NSMutableArray* filteredResult = [NSMutableArray arrayWithCapacity:[descs count]];
	
	// create a set of names
	NSSet* nameSet = [NSSet setWithArray:[NTFileDesc descsToNames:descs]];
	
	BOOL add;
	NTFileDesc* desc;
	
	for (desc in descs)
	{
		add = YES;
		NSString* name = [desc nameWhenCreated];
		
		// use name when created since it's cached and fast
		if ([name hasPrefix:@"._"])
		{
			name = [name substringFromIndex:2];
			
			// now see if this ._ files data file is also in our list				
			if ([nameSet containsObject:name])
				add = NO;
		}
		
		if (add)
			[filteredResult addObject:desc];
	}
	
	return filteredResult;
}

+ (BOOL)parentDirectoriesWritable:(NSArray*)sources;
{
	NTFileDesc* desc;
	
	for (desc in sources)
	{
		// if volume is readOnly, just continue, a copy will naturally happen in the engine
		NTFileDesc* parent = [desc parentDesc];
		
		if (parent)
		{
			if (![parent isWritable])
				return NO;
		}
		else
			return NO;  // no parent (we are computer?)
	}
	
	return YES;
}

+ (BOOL)directoriesWritable:(NSArray*)sources;
{
	NTFileDesc* desc;
	
	for (desc in sources)
	{
		// if volume is readOnly, just continue, a copy will naturally happen in the engine
		if (![desc isWritable])
			return NO;
	}
	
	return YES;
}

// -[NTFileDesc valence] returns 0 for non-HFS disks, so use this instead
- (UInt32)valenceForNonHFS;
{
	if ([self FSRefPtr] && [self isDirectory])
	{
		FSCatalogInfo catalogInfo;
		OSErr err = FSGetCatalogInfo([self FSRefPtr], kFSCatInfoValence, &catalogInfo, NULL, NULL, NULL);
		
		if (!err)
			return catalogInfo.valence;    
	}
	
	return 0;
}


+ (BOOL)descOK:(NTFileDesc*)desc;
{
    // an empty string is a valid path to all mounted media
    if ([desc isComputer])
        return YES;
	
	return (access([desc fileSystemPath], F_OK) == 0);
}

+ (void)deleteResourceFork:(NTFileDesc*)desc;
{
    HFSUniStr255 forkName;
    OSErr err;
	
    err = FSGetResourceForkName(&forkName);
	
    if (err == noErr)
        err = FSDeleteFork([desc FSRefPtr], forkName.length, forkName.unicode);
}

+ (void)deleteDataFork:(NTFileDesc*)desc;
{
    HFSUniStr255 forkName;
    OSErr err;
	
    err = FSGetDataForkName(&forkName);
	
    if (err == noErr)
        err = FSDeleteFork([desc FSRefPtr], forkName.length, forkName.unicode);
}

+ (void)setResourceFork:(NTFileDesc*)desc length:(UInt64)length;
{
    HFSUniStr255 forkName;
    OSErr err;
	
    err = FSGetResourceForkName(&forkName);
	
    if (err == noErr)
    {
        FSIORefNum forkRefNum;
				
        err = FSOpenFork([desc FSRefPtr], forkName.length, forkName.unicode, fsWrPerm, &forkRefNum);
        if (err == noErr)
        {
            err = FSSetForkSize(forkRefNum, fsFromStart, length);
            FSCloseFork(forkRefNum);
        }
    }
}

+ (void)setDataFork:(NTFileDesc*)desc length:(UInt64)length;
{
    HFSUniStr255 forkName;
    OSErr err;
	
    err = FSGetDataForkName(&forkName);
	
    if (err == noErr)
    {
        FSIORefNum forkRefNum;
		
        err = FSOpenFork([desc FSRefPtr], forkName.length, forkName.unicode, fsWrPerm, &forkRefNum);
        if (err == noErr)
        {
            err = FSSetForkSize(forkRefNum, fsFromStart, length);
            FSCloseFork(forkRefNum);
        }
    }
}

+ (BOOL)hasResourceFork:(NTFileDesc*)desc;
{
    CatPositionRec iterator;
    HFSUniStr255 rsrcForkName;
    HFSUniStr255 thisForkName;
    SInt64 thisForkSize;
    OSStatus err=noErr;
    BOOL result = NO;
	
	iterator.initialize = 0;
	BOOL done = false;
	
	FSGetResourceForkName(&rsrcForkName);
	
    while (!err && !done)
    {
        err = FSIterateForks([desc FSRefPtr], &iterator, &thisForkName, &thisForkSize, NULL);
        if (err == errFSNoMoreItems)
            break;
        else if (!err)
        {
			if ([NTPathUtilities compareHFSUniStr255:&thisForkName rhs:&rsrcForkName])
			{
				result = YES;
				break;
			}
        }
    }
	
	return result;
}

+ (NSString*)permissionOctalStringForModeBits:(unsigned long)modeBits;
{
    int chmodNum;
    UInt32 permBits = (modeBits & ACCESSPERMS);
	
	// add - chmod 755
	chmodNum = 100 * ((permBits & S_IRWXU) >> 6);  // octets
	chmodNum += 10 * ((permBits & S_IRWXG) >> 3);
	chmodNum += 1 * (permBits & S_IRWXO);
	
	char buff[20];
	snprintf(buff, 20, "%03d", chmodNum);
	
	return [NSString stringWithUTF8String:buff];
}

+ (NSString*)permissionsTextForDesc:(NTFileDesc*)desc includeOctal:(BOOL)includeOctal;
{
    return [self permissionsTextForModeBits:[desc posixFileMode] includeOctal:includeOctal];
}

+ (NSString*)permissionsTextForModeBits:(unsigned long)modeBits includeOctal:(BOOL)includeOctal;
{
    NSString* perm = @"";
    unsigned long permBits = (modeBits & ACCESSPERMS);
	
    if (S_ISDIR(modeBits))
        perm = [perm stringByAppendingString:@"d"];
    else if (S_ISCHR(modeBits))
        perm = [perm stringByAppendingString:@"c"];
    else if (S_ISBLK(modeBits))
        perm = [perm stringByAppendingString:@"b"];
    else if (S_ISLNK(modeBits))
        perm = [perm stringByAppendingString:@"l"];
    else if (S_ISSOCK(modeBits))
        perm = [perm stringByAppendingString:@"s"];
    else if (S_ISWHT(modeBits))
        perm = [perm stringByAppendingString:@"w"];
    else if (S_ISREG(modeBits))
        perm = [perm stringByAppendingString:@"-"];
    else
        perm = [perm stringByAppendingString:@" "];  // what is it?
	
    // Owner
    perm = [perm stringByAppendingString:(permBits & S_IRUSR) ? @"r" : @"-"];
    perm = [perm stringByAppendingString:(permBits & S_IWUSR) ? @"w" : @"-"];
	
    if (permBits & S_IXUSR)
    {
        if ((S_ISUID & modeBits) || (S_ISGID & modeBits))
            perm = [perm stringByAppendingString:@"s"];
        else
            perm = [perm stringByAppendingString:@"x"];
    }
    else
    {
        if ((S_ISUID & modeBits) || (S_ISGID & modeBits))
            perm = [perm stringByAppendingString:@"S"];
        else
            perm = [perm stringByAppendingString:@"-"];
    }
	
    // Group
    perm = [perm stringByAppendingString:(permBits & S_IRGRP) ? @"r" : @"-"];
    perm = [perm stringByAppendingString:(permBits & S_IWGRP) ? @"w" : @"-"];
	
    if (permBits & S_IXGRP)
    {
        if ((S_ISUID & modeBits) || (S_ISGID & modeBits))
            perm = [perm stringByAppendingString:@"s"];
        else
            perm = [perm stringByAppendingString:@"x"];
    }
    else
    {
        if ((S_ISUID & modeBits) || (S_ISGID & modeBits))
            perm = [perm stringByAppendingString:@"S"];
        else
            perm = [perm stringByAppendingString:@"-"];
    }
	
    // Others
    perm = [perm stringByAppendingString:(permBits & S_IROTH) ? @"r" : @"-"];
    perm = [perm stringByAppendingString:(permBits & S_IWOTH) ? @"w" : @"-"];
	
    if (permBits & S_IXOTH)
    {
        if ((S_ISUID & modeBits) || (S_ISGID & modeBits))
            perm = [perm stringByAppendingString:@"s"];
        else
        {
            // check sticky bit
            if (S_ISVTX & modeBits)
                perm = [perm stringByAppendingString:@"t"];
            else
                perm = [perm stringByAppendingString:@"x"];
        }
    }
    else
    {
        if ((S_ISUID & modeBits) || (S_ISGID & modeBits))
            perm = [perm stringByAppendingString:@"S"];
        else
        {
            // check sticky bit
            if (S_ISVTX & modeBits)
                perm = [perm stringByAppendingString:@"T"];
            else
                perm = [perm stringByAppendingString:@"-"];
        }
    }
	
	if (includeOctal)
	{    
		perm = [perm stringByAppendingString:@" ("];
		perm = [perm stringByAppendingString:[self permissionOctalStringForModeBits:modeBits]];
		perm = [perm stringByAppendingString:@")"];
	}
	
    return perm;
}

+ (void)copy:(NTFileDesc*)srcDesc fromDataFork:(BOOL)fromDataFork to:(NTFileDesc*)destDesc toDataFork:(BOOL)toDataFork;
{
    HFSUniStr255 rsrcForkName, dataForkName;
    OSErr err;
	
    err = FSGetResourceForkName(&rsrcForkName);
    err = FSGetDataForkName(&dataForkName);
	
    if (err == noErr)
    {
        FSIORefNum srcFork, destFork;
		
        if (fromDataFork)
            err = FSOpenFork([srcDesc FSRefPtr], dataForkName.length, dataForkName.unicode, fsRdPerm, &srcFork);
        else
            err = FSOpenFork([srcDesc FSRefPtr], rsrcForkName.length, rsrcForkName.unicode, fsRdPerm, &srcFork);
		
        if (err == noErr)
        {
            if (toDataFork)
                err = FSOpenFork([destDesc FSRefPtr], dataForkName.length, dataForkName.unicode, fsWrPerm, &destFork);
            else
                err = FSOpenFork([destDesc FSRefPtr], rsrcForkName.length, rsrcForkName.unicode, fsWrPerm, &destFork);
			
            if (err == noErr)
            {
                SInt64 srcSize, bytesRemaining, bytesToReadThisTime, bytesToWriteThisTime, bufferSize = (4*1024)*100;
                char* buffer = ( char* ) malloc(bufferSize );
				
                FSGetForkSize(srcFork, &srcSize);
                FSSetForkSize(destFork, fsFromStart, srcSize);
				
                bytesRemaining = srcSize;
                while (err == noErr && bytesRemaining != 0)
                {
                    if (bytesRemaining > bufferSize)
                    {
                        bytesToReadThisTime  = 	bufferSize;
                        bytesToWriteThisTime = 	bytesToReadThisTime;
                    }
                    else
                    {
                        bytesToReadThisTime  = 	bytesRemaining;
                        bytesToWriteThisTime = 	bytesToReadThisTime;
                    }
					
                    err = FSReadFork(srcFork, fsAtMark + noCacheMask, 0, bytesToReadThisTime, buffer, NULL);
                    if (err == noErr)
                        err = FSWriteFork(destFork, fsAtMark + noCacheMask, 0, bytesToWriteThisTime, buffer, NULL);
                    if (err == noErr)
                        bytesRemaining -= bytesToReadThisTime;
                }
				
                free(buffer);
				
                FSCloseFork(destFork);
            }
			
            FSCloseFork(srcFork);
        }
    }
}

@end
