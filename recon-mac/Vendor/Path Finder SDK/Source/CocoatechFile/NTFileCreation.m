//
//  NTFileCreation.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 5/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFileCreation.h"
#import <sys/stat.h>
#import <unistd.h>
#import "NTFilePreflightTests.h"
#import "NTFileNamingManager.h"
#import "NTAliasFileManager.h"

@implementation NTFileCreation

+ (NTFileDesc*)newFolder:(NSString*)path permissions:(unsigned)permissions;
{
    NTFileDesc *result=nil;
		
    if (permissions == 0)
        permissions = 0755;
	
    mode_t oldmask = umask(0);
    BOOL created = (mkdir([path fileSystemRepresentation], permissions) == 0);
    umask(oldmask);
    
	if (created)
	{
		result = [NTFileDesc descNoResolve:path];
		if (![result isValid])
			result = nil;
	}
	else
		NSLog(@"mkdir failed:%d %@", errno, path);
		
    return result;
}

+ (NTFileDesc*)newFile:(NSString*)path permissions:(unsigned)permissions;
{
    NTFileDesc *result=nil;
	
    if (permissions == 0)
        permissions = 0644;
	
    mode_t oldmask = umask(0);
    int fd = open([path fileSystemRepresentation], O_CREAT | O_TRUNC | O_WRONLY, permissions);
    umask(oldmask);
	
    if (fd != -1)
    {
        close(fd);  // need to close the file
		
        result = [NTFileDesc descNoResolve:path];
        if (![result isValid])
			result = nil;
	}
	else
		NSLog(@"open(create) failed:%d %@", errno, path);
	
    return result;
}

// creates a unique name automatically
+ (NTFileDesc*)makeAlias:(NTFileDesc*)source
	  inDirectory:(NTFileDesc*)directory
		aliasType:(NTAliasType)type; 
{
	return [self makeAlias:source
				inDirectory:directory
				  aliasType:type
		   withName:nil];		
}

	// uses a specific name, if it conflicts with an existing name, it makes a unique name
+ (NTFileDesc*)makeAlias:(NTFileDesc*)source
	  inDirectory:(NTFileDesc*)directory
		aliasType:(NTAliasType)aliasType
		 withName:(NSString*)name; 
{
	if (!directory)
		directory = [source parentDesc];
	
	if (![NTFilePreflightTests isSourceValid:source])
		return nil;
	
    if (![NTFilePreflightTests isDestinationValid:directory])
        return nil;
	
	BOOL namePassedIn = YES;
	if (![name length])
	{
		namePassedIn = NO;
		name = [source name];
	}	
	
	NSString* fileTag=nil;
	NSString* extension=nil;
	
	switch (aliasType)
	{
		case NTCarbonAliasType:
			fileTag = [NTLocalizedString localize:@"alias"];
			break;
		case NTPathFinderAliasType:
			extension = kPathFinderAliasExtension;
			break;
		case NTSymlinkType:
			fileTag = [NTLocalizedString localize:@"link"];
			break;
	}
		
	if (namePassedIn)
		fileTag = nil;

	// only add fileTag if the source and dest directories are the same
	if (fileTag && ![directory isEqualToDesc:[source parentDesc]])
		fileTag = nil;
	
	name = [name strictStringByDeletingPathExtension]; // don't want original extension
	
	NSString* destPath = [directory path];
	destPath = [destPath stringByAppendingPathComponent:name];
	
	// add extension for Path Finder alias if needed
	if (extension)
		destPath = [destPath stringByAppendingPathExtension:extension];

	// get a unique name
	destPath = [[NTFileNamingManager sharedInstance] uniqueName:destPath with:fileTag];
	
	NTFileDesc* aliasDesc=nil;
    switch (aliasType)
	{
		case NTSymlinkType:
		{
			int result = (symlink([source fileSystemPath], [destPath fileSystemRepresentation]) == 0);
			if (result)
				aliasDesc = [NTFileDesc descNoResolve:destPath];
		}
			break;
		case NTPathFinderAliasType:
			aliasDesc = [NTAliasFileManager createPathFinderAliasFile:source atPath:destPath];
			break;
		case NTCarbonAliasType:
		default:
			aliasDesc = [NTAliasFileManager createAliasFile:source atPath:destPath];
			break;
	}	
		
	return aliasDesc;
}

@end
