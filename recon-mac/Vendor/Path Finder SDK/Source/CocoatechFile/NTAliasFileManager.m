//
//  NTAliasFileManager.m
//  CocoatechFile
//
//  Created by sgehrman on Fri Jul 13 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NTAliasFileManager.h"
#import <sys/stat.h>
#import "NTFileModifier.h"
#import "NTResourceMgr.h"
#import "NTIconFamily.h"
#import "NTAlias.h"
#import "NTIconStore.h"
#import "NTIconStore.h"
#import "NSImage-CocoatechFile.h"

@interface NTAliasFileManager (Private)
+ (NTFileDesc*)doCreateAliasFile:(NTFileDesc*)desc atPath:(NSString*)destPath dataFork:(BOOL)dataFork;
+ (NTFileDesc*)doResolveAliasFile:(NTFileDesc*)desc resolveServer:(BOOL)resolveServer outIsServerAlias:(BOOL*)outIsServerAlias dataFork:(BOOL)dataFork;
@end

@implementation NTAliasFileManager

+ (NTFileDesc*)resolveNetworkAliasFile:(NTFileDesc*)desc;
{
    NTFileDesc *resolvedDesc = nil;
    Boolean targetIsFolder, wasAliased;
    OSErr err;
    Boolean resolveChains = true;
    FSRef fsRef = *[desc FSRefPtr];

	err = FSResolveAliasFile(&fsRef, resolveChains, &targetIsFolder, &wasAliased);	

    if (err == noErr && wasAliased)
        resolvedDesc = [NTFileDesc descFSRef:&fsRef];

    return resolvedDesc;
}

+ (NTFileDesc*)createAliasFile:(NTFileDesc*)desc atPath:(NSString*)destPath;
{
    NTFileDesc* aliasFile = [self doCreateAliasFile:desc atPath:destPath dataFork:NO];
    
	if (aliasFile)
	{
		// sets the custom icon and type/creator
		[self setupAliasFile:aliasFile forDesc:desc];
	}
	
    return aliasFile;
}

+ (NTFileDesc*)createPathFinderAliasFile:(NTFileDesc*)desc atPath:(NSString*)destPath;
{
    NTFileDesc* aliasDesc = [self doCreateAliasFile:desc atPath:destPath dataFork:YES];
    
    if (aliasDesc)
    {        
        // rename with extension
        if (![aliasDesc isPathFinderAlias])  // check if the extension is correct already
        {
            NSString* newName = [[aliasDesc name] strictStringByDeletingPathExtension];
            
            newName = [newName stringByAppendingPathExtension:kPathFinderAliasExtension];

            [aliasDesc rename:newName err:nil];
                    
            if (![aliasDesc isValid])
                aliasDesc = nil;
        }
                
        if ([aliasDesc isValid])
        {
            NTIconFamily* iconFamily = [NTIconFamily iconFamilyWithIconOfFile:desc];
            NSImage *image = [iconFamily image];
            
            // add the alias badge to all imageReps so it looks good
            image = [image imageWithBadge:[[NTIconStore sharedInstance] aliasBadge]];
                
            // convert back to iconFamily
            iconFamily = [NTIconFamily iconFamilyWithImage:image];
            
            // now set that icon family as a custom icon
            [iconFamily setAsCustomIconForFile:aliasDesc];
            
            // hide extension
            [NTFileModifier setExtensionHidden:YES desc:aliasDesc];
        }
    }
    
    return aliasDesc;
}

+ (NTFileDesc*)resolveAliasFile:(NTFileDesc*)desc resolveServer:(BOOL)resolveServer outIsServerAlias:(BOOL*)outIsServerAlias;
{
	return [self doResolveAliasFile:desc resolveServer:resolveServer outIsServerAlias:outIsServerAlias dataFork:NO];
}

+ (NTFileDesc*)resolvePathFinderAliasFile:(NTFileDesc*)desc resolveServer:(BOOL)resolveServer outIsServerAlias:(BOOL*)outIsServerAlias;
{
	return [self doResolveAliasFile:desc resolveServer:resolveServer outIsServerAlias:outIsServerAlias dataFork:YES];
}

// alias handle becomes owned by the Resource manager, so don't dispose yourself
+ (BOOL)addAliasResource:(AliasHandle)alias toFile:(FSRef*)ref dataFork:(BOOL)dataFork;
{
	HFSUniStr255 forkName;
	ResFileRefNum refNum;
	OSErr err;
	
	if (dataFork)
		err = FSGetDataForkName(&forkName);
	else
		err = FSGetResourceForkName(&forkName);
	
	err = FSOpenResourceFile(ref, forkName.length,forkName.unicode, fsRdWrPerm, &refNum);
	if (!err)
	{
		short oldResFile = CurResFile();
		UseResFile(refNum);
		
		// must remove old one?  seems to be appending the data which is strange
		Handle oldHandle = Get1Resource(rAliasType, 0);
		if (oldHandle)
		{
			RemoveResource(oldHandle);
			UpdateResFile(refNum);
			DisposeHandle(oldHandle);
		}
		
		AddResource((Handle) alias, rAliasType, 0, "\p");
		UpdateResFile(refNum);
		ReleaseResource((Handle)alias);
		
		UseResFile(oldResFile);
		
		CloseResFile(refNum);
		
		if (err == noErr)
			return YES;
	}
	
	return NO;
}

// updates the custom icon and type/creator for an alias file
+ (void)setupAliasFile:(NTFileDesc*)aliasFile forDesc:(NTFileDesc*)desc;
{
	FileInfo fileInfo = *[desc fileInfo];
	
	// set alias types for special folders	
	OSType type = [NTAlias fileTypeForAliasFileOfDesc:desc];
	if (type)
	{
		fileInfo.fileType = type;
		fileInfo.fileCreator = 'MACS';
	}
	
	fileInfo.finderFlags = kIsAlias; // set the alias finder flag
	
	// set the file information or the new file
	[NTFileModifier setFileInfo:&fileInfo desc:aliasFile];
	
	// files and applications always get a custom icon
	if ([desc isFile] || [desc isPackage])
	{
		// for files, we always set a custom icon so the alias file matches the original
		[[NTIconFamily iconFamilyWithIconOfFile:desc] setAsCustomIconForFile:aliasFile];
	}
	else if ([desc isDirectory])
	{
		// directories only get a custom icon if they already have a custom icon
		if ([NTIconFamily hasCustomIconForDirectory:desc])
			[[NTIconFamily iconFamilyWithIconOfFile:desc] setAsCustomIconForDirectory:aliasFile];
	}            
}

@end

@implementation NTAliasFileManager (Private)

+ (NTFileDesc*)doCreateAliasFile:(NTFileDesc*)desc atPath:(NSString*)destPath dataFork:(BOOL)dataFork;
{
    AliasHandle alias = [NTAlias aliasHandleForDesc:desc];
    OSStatus err=-666;
    
    if (alias)
    {
        FileInfo fileInfo;
        FSRef parentRef, destRef;
        NSString* destName = [destPath lastPathComponent];
        NSString* parentPath = [destPath stringByDeletingLastPathComponent];
        unichar unicodeName[[destName length]];
        HFSUniStr255 forkName;
        
        fileInfo = *[desc fileInfo];
        
        // file name must be an hfs plus compatible name : must be coverted to /
        destName = [destName stringByReplacing:@":" with:@"/"];
        
        [destName getCharacters:unicodeName];
        
        if (dataFork)
            err = FSGetDataForkName(&forkName);
        else
            err = FSGetResourceForkName(&forkName);
                
        err = FSPathMakeRef((const UInt8 *)[parentPath UTF8String], &parentRef, NULL);
        if (err) return nil;
        
        err = FSCreateResourceFile(&parentRef, [destName length], unicodeName, 0, nil, forkName.length,forkName.unicode, &destRef, nil);
        if (err) return nil;
        
		BOOL success = [self addAliasResource:alias toFile:&destRef dataFork:dataFork];
		if (success)
			return [NTFileDesc descFSRef:&destRef];
    }
	
    return nil;
}

+ (NTFileDesc*)doResolveAliasFile:(NTFileDesc*)desc resolveServer:(BOOL)resolveServer outIsServerAlias:(BOOL*)outIsServerAlias dataFork:(BOOL)dataFork;
{
	NTFileDesc* result = nil;
	
	if (!dataFork)
	{
		// added this in PF 4 so we could work with Volume aliases, I think the old method was for thread safety anyway, so probably only needed for Path Finder aliases.
		result = [NTAlias resolveAliasFile:desc 
					   resolveIfRequiresUI:resolveServer 
			   outAliasRequiresUIToResolve:outIsServerAlias];;
	}
	else
	{
		
		NSData* aliasData = [NTAlias aliasResourceFromAliasFile:desc dataFork:dataFork];
		if (aliasData)
		{
			BOOL wasChanged;
			AliasHandle aliasHandle = (AliasHandle)[aliasData carbonHandle];
			
			result = [NTAlias resolveAlias:aliasHandle resolveIfRequiresUI:resolveServer outAliasRequiresUIToResolve:outIsServerAlias outWasChanged:&wasChanged];
			
			DisposeHandle((Handle) aliasHandle);
		}
	}
	
	return result;
}

@end