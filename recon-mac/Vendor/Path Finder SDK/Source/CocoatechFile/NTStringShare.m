//
//  NTStringShare.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Sat Dec 06 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NTStringShare.h"
/*

Kind strings and file extensions aren't that varied.  Rather than every object owning their own copy of the string "txt", or "Text Document", this class allows them to share the same instance

*/

@interface NTStringShare (DelayedSelectors)
- (void)combineExtensionSets:(id)object;
- (void)combineKindStringSets:(id)object;
@end

@interface NTStringShare (Private)
- (NSMutableSet*)defaultKindStrings;
- (NSMutableSet*)defaultExtensions;

- (NSMutableSet *)kindStrings;
- (void)setKindStrings:(NSMutableSet *)theKindStrings;

- (NSMutableSet *)extensionStrings;
- (void)setExtensionStrings:(NSMutableSet *)theExtensionStrings;

- (NSLock *)kindLock;
- (void)setKindLock:(NSLock *)theKindLock;

- (NSLock *)extensionLock;
- (void)setExtensionLock:(NSLock *)theExtensionLock;
@end

@implementation NTStringShare

+ (void)initialize;
{
	NTINITIALIZE;
	[self sharedInstance];
}

- (id)init;
{
    self = [super init];
        
	[self setKindLock:[[[NSLock alloc] init] autorelease]];
    [self setExtensionLock:[[[NSLock alloc] init] autorelease]];

	[self setKindStrings:[self defaultKindStrings]];
    [self setExtensionStrings:[self defaultExtensions]];

    return self;
}

- (void)dealloc;
{
	[self setKindStrings:nil];
    [self setExtensionStrings:nil];
    [self setKindLock:nil];
    [self setExtensionLock:nil];

    [super dealloc];
}

+ (NTStringShare*)sharedInstance;
{
	static BOOL initialized = NO;
    static NTStringShare* shared = nil;
    
	// the localization logger was causing an endless loop here
	// must be enabled to see it happen
	if (!initialized)
	{
		initialized = YES;

		if (!shared)
			shared = [[NTStringShare alloc] init];
    }
	
    return shared;
}

- (NSString*)sharedKindString:(NSString*)kindString;
{
    if (kindString && [kindString length])
    {
        if ([[self kindLock] tryLock])
        {
            NSString* result = [[self kindStrings] member:kindString];
            if (!result)
            {
                [[self kindStrings] addObject:kindString];
                
                result = kindString;
            }
            
            [[self kindLock] unlock];
            
            return result;
        }
    }
    
    return kindString;
}

- (NSString*)sharedExtensionString:(NSString*)extensionString;
{
    if (extensionString && [extensionString length])
    {    
        if ([[self extensionLock] tryLock])
        {
            NSString* result = [[self extensionStrings] member:extensionString];
            if (!result)
            {
                [[self extensionStrings] addObject:extensionString];
                
                result = extensionString;
            }
            
            [[self extensionLock] unlock];
            
            return result;
        }
    }
    
    return extensionString;
}

@end

// ===============================================================================================================

@implementation NTStringShare (StandardKindStrings)

+ (NSString*)packageKindString;
{
    static NSString* shared=nil;
    
    if (!shared)
        shared = [[NTLocalizedString localize:@"Package" table:@"CocoaTechFoundation"] retain];
    
    return shared;
}

+ (NSString*)volumeKindString;
{
    static NSString* shared=nil;
    
    if (!shared)
        shared = [[NTLocalizedString localize:@"Volume" table:@"CocoaTechFoundation"] retain];
    
    return shared;
}

+ (NSString*)folderKindString;
{
    static NSString* shared=nil;
    
    if (!shared)
        shared = [[NTLocalizedString localize:@"Folder" table:@"CocoaTechFoundation"] retain];
    
    return shared;
}

+ (NSString*)symbolicLinkKindString;
{
    static NSString* shared=nil;
    
    if (!shared)
        shared = [[NTLocalizedString localize:@"Symbolic Link" table:@"CocoaTechFoundation"] retain];
    
    return shared;
}

+ (NSString*)documentKindString;
{
    static NSString* shared=nil;
    
    if (!shared)
        shared = [[NTLocalizedString localize:@"Document" table:@"CocoaTechFoundation"] retain];
    
    return shared;
}

@end

// =====================================================================================

@implementation NTStringShare (Private)

- (NSMutableSet*)defaultExtensions;
{
    return [[[NSMutableSet alloc] initWithObjects:
        @"txt",
        @"text",
        @"doc",
        @"rtf",
        @"rtfd",
        
        @"html",
        @"htm",
        @"php",
        @"cgi",
        
        @"c",
        @"m",
        @"h",
        @"cp",
        @"cpp",
        @"cc",
        @"mm",
        @"sh",
        @"in",
        @"xml",
        @"rb",
        @"pl",
        @"plx",
        @"xsl",
        @"pm",
        @"css",
        @"spec",
        @"lsm",
        @"csh",
        @"r",
        @"java",
        @"plist",
        @"info",
        
        @"mov",
        @"fcp",
        @"swf",
        @"mpeg",
        @"mpg",
        @"mp3",
        @"mp4",
        @"avi",
        @"snd",
        @"wav",
        @"au",
        @"aif",
        @"aiff",
        
        @"ai",
        @"eps",
        @"tif",
        @"tiff",
        @"gif",
        @"jpg",
        @"jpeg",
        @"pdf",
        @"icns",
        @"ico",
        
        @"dmg",
        @"img",
        @"smi",
        @"toast",
        
        @"ape",

        @"tgz",
        @"zip",
        @"gz",
        @"sit",
        @"sitx",
        @"pkg",
        
        @"webloc",
        @"help",
        @"obj",
        @"localized",
        @"url",
        @"applescript",
        @"plugin",
        @"cfg",
        @"dic",
        @"dat",
        @"js",
        @"jar",
        @"class",
        @"png",
        @"scriptSuite",
        @"scriptTerminology",
        @"app",
        @"rpm",
        @"lproj",

        @"acb",
        @"aco",
        @"grd",
        @"irs",
        @"pat",
        @"abr",
        @"atn",
        @"scpt",
        @"menu",
        @"dtd",
        @"sql",
        @"ini",
        @"pbproj",
        @"asf",
        @"mpkg",
        @"psd",
        @"zvt",
        @"tpl",
        @"asl",
        @"act",
        @"iros",
        @"ent",

        nil] autorelease];
}

- (NSMutableSet*)defaultKindStrings;
{
    return [[[NSMutableSet alloc] initWithObjects:
        
        [NTStringShare packageKindString],
        [NTStringShare volumeKindString],
        [NTStringShare folderKindString],
        [NTStringShare symbolicLinkKindString],
        [NTStringShare documentKindString],        
        
        nil] autorelease];
}


//---------------------------------------------------------- 
//  kindStrings 
//---------------------------------------------------------- 
- (NSMutableSet *)kindStrings
{
    return mKindStrings; 
}

- (void)setKindStrings:(NSMutableSet *)theKindStrings
{
    if (mKindStrings != theKindStrings) {
        [mKindStrings release];
        mKindStrings = [theKindStrings retain];
    }
}

//---------------------------------------------------------- 
//  extensionStrings 
//---------------------------------------------------------- 
- (NSMutableSet *)extensionStrings
{
    return mExtensionStrings; 
}

- (void)setExtensionStrings:(NSMutableSet *)theExtensionStrings
{
    if (mExtensionStrings != theExtensionStrings) {
        [mExtensionStrings release];
        mExtensionStrings = [theExtensionStrings retain];
    }
}


//---------------------------------------------------------- 
//  kindLock 
//---------------------------------------------------------- 
- (NSLock *)kindLock
{
    return mKindLock; 
}

- (void)setKindLock:(NSLock *)theKindLock
{
    if (mKindLock != theKindLock) {
        [mKindLock release];
        mKindLock = [theKindLock retain];
    }
}

//---------------------------------------------------------- 
//  extensionLock 
//---------------------------------------------------------- 
- (NSLock *)extensionLock
{
    return mExtensionLock; 
}

- (void)setExtensionLock:(NSLock *)theExtensionLock
{
    if (mExtensionLock != theExtensionLock) {
        [mExtensionLock release];
        mExtensionLock = [theExtensionLock retain];
    }
}

@end


