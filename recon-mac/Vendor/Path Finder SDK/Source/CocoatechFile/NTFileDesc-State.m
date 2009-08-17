//
//  NTFileDesc-State.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFileDesc-State.h"
#import "NTFileDesc-Private.h"
#import "NTFileDescData.h"

// a quick check to see if we have the icon information yet
// this is used for situations for speed where we want to draw what we have and not delay the main thread getting more stuff off the disk (or network)

@implementation NTFileDesc (State)

- (BOOL)itemInfo_initialized;
{
	return [[self cache] itemInfo_initialized:nil];
}

- (BOOL)hasDirectoryContents_initialized;
{
	return [[self cache] hasDirectoryContents_initialized:nil];
}

- (BOOL)displayName_initialized;
{
	return [[self cache] displayName_initialized:nil];
}

- (BOOL)attributeDate_initialized;
{
	return [[self cache] attributeDate_initialized:nil];
}

- (BOOL)creationDate_initialized;
{
	return [[self cache] creationDate_initialized:nil];
}

- (BOOL)modificationDate_initialized;
{
	return [[self cache] modificationDate_initialized:nil];
}

- (BOOL)kindString_initialized;
{
	return [[self cache] kind_initialized:nil];
}

- (BOOL)icon_intialized;
{
	return [[self cache] icon_initialized:nil];
}

// a quick check to see if we have the information yet
// this is used for situations for speed where we want to draw what we have and not delay the main thread getting more stuff off the disk (or network)
- (BOOL)size_initialized;
{
	if ([self isFile])
		return [[self cache] fileSize_initialized:nil];
	
	return NO;
}

- (BOOL)physicalSize_initialized;
{
	if ([self isFile])
		return [[self cache] physicalFileSize_initialized:nil];
	
	return NO;
}

@end
