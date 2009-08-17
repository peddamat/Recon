//
//  NTWeblocFile.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Thu Mar 20 2003.
//  Copyright (c) 2003 CocoaTech. All rights reserved.
//


/*

 When you use the Drag Manager to drag some data to a Finder window or to the desktop,
 you create a clipping file. The format of these is not documented anywhere that I know, and
 obviously it could change in future. Nevertheless, it's clear that any future change has to
 be backward-compatible with the way they currently work.

 The following is my collection of guesses as to how the format works.

 Clipping files have creator code 'drag', and one of four file types: 'clpt' for a text
 clipping, 'clpp' for a picture clipping, 'clps' for a sound clipping, and 'clpu' for
 everything else. The format for all these types is identical, and all the data is kept in the resource fork.

 The 'drag' resource lists all the other resources containing the different flavours
 of the drag item. It always seems to have an ID of 128. It begins with a 16-byte DragMapHeader,
 followed by some number of 16-byte DragMapEntry records:

 TYPE
 (* layout of the drag map resource in a clipping file *)
 DragMapHeader =
 RECORD
 MapVersion : LONGCARD; (* = 1 *)
 Unused1, Unused2 : LONGCARD; (* = 0 *)
 NrTypes : LONGCARD;
 (* Entry : ARRAY [1 .. NrTypes] OF DragMapEntry *)
 END (*RECORD*);
 DragMapEntry =
 RECORD
 EntryType : OSType; (* resource type *)
 Unused1 : ShortCard; (* = 0 *)
 EntryID : ResID; (* resource ID *)
 Unused2, Unused3 : LONGCARD; (* = 0 *)
 END (*RECORD*);

 Each DragMapEntry lists the type and ID of the resource containing the data for that
 particular item flavour. The resource type is the flavour type
 (eg 'PICT' for a QuickDraw picture, 'snd ' for a sound, and so on).
 In all the clipping files that I've seen, the flavour resource IDs are always 128.

 */

#import "NTWeblocFile.h"
#import "NTResourceMgr.h"
#import "NTFileModifier.h"
#import "NTResourceFork.h"
#import "NTPathUtilities.h"

static OSType kDragWeblocType = 'drag';
static OSType kURLWeblocType = 'url ';
static OSType kTEXTWeblocType = 'TEXT';
static OSType kRTFWeblocType = 'RTF ';
static OSType kUnicodeWeblocType = 'utxt';
static OSType kUTF8WeblocType = 'utf8';

static OSType kTEXTWeblocFileType = 'clpt';
static OSType kWeblocFileCreator = 'MACS';

// =================================================================================
// types used inside a webloc file

// type  'TEXT' - just plain text "http://www.cocoatech.com"
// type  'url' - just plain text "http://www.cocoatech.com"
// type  'drag' - WLDragMapHeaderStruct with n WLDragMapEntries

#pragma options align=mac68k

typedef struct WLDragMapHeaderStruct
{
    long mapVersion;  // always 1
    long unused1;     // always 0
    long unused2;     // always 0
    short unused;
    short numEntries;   // number of repeating WLDragMapEntries
} WLDragMapHeaderStruct;

typedef struct WLDragMapEntryStruct
{
    OSType type;
    short unused;  // always 0
    ResID resID;   // always 128 or 256?
    long unused1;   // always 0
    long unused2;   // always 0
} WLDragMapEntryStruct;

#pragma options align=reset

// =================================================================================

@interface WLDragMapEntry : NSObject
{
    OSType _type;
    ResID _resID;
}

+ (id)entryWithType:(OSType)type resID:(int)resID;

- (OSType)type;
- (ResID)resID;
- (NSData*)entryData;

@end

// =================================================================================

@interface NTWeblocFile (Private)
+ (NSURL*)extractUrlFromWeblocFile:(NTFileDesc*)desc;
+ (NSAttributedString*)extractStringFromWeblocFile:(NTFileDesc*)desc;

+ (NSArray*)readEntriesFromWeblocFile:(NTFileDesc*)desc;

- (void)setURL:(NSURL*)url;
- (void)setString:(id)string;

- (NSData*)dragDataWithEntries:(NSArray*)array;
+ (void)swapWLDragMapHeader:(WLDragMapHeaderStruct*)map;
+ (void)swapWLDragMapEntry:(WLDragMapEntryStruct*)entry;
@end

// =================================================================================

@implementation NTWeblocFile

+ (BOOL)isHTTPWeblocFile:(NTFileDesc*)desc;
{
    if ([desc isFile])
    {
        if ([desc creator] == kInternetLocationCreator || [desc creator] == kWeblocFileCreator)
            return ([desc type] == kInternetLocationHTTP);
        else if ([[desc extension] isEqualToStringCaseInsensitive:@"webloc"])
            return YES;
    }
    
    return NO;
}

+ (BOOL)isServerWeblocFile:(NTFileDesc*)desc;
{
    if ([desc isFile])
    {
        if ([desc creator] == kInternetLocationCreator || [desc creator] == kWeblocFileCreator)
        {
            if ([desc type] == kInternetLocationAFP ||
                [desc type] == kInternetLocationAppleTalk ||
                [desc type] == kInternetLocationNSL ||
                [desc type] == kInternetLocationFTP ||
                [desc type] == kInternetLocationGeneric)
            {
                return YES;
            }
        }
    }
    
    return NO;
}

// returns nil if not a webloc, or not a server alias file at all
+ (NSURL*)urlFromWeblocFile:(NTFileDesc*)desc;
{
    NSURL* url=nil;
    
    if ([self isServerWeblocFile:desc] || [self isHTTPWeblocFile:desc])
    {
        NTWeblocFile* webloc = [self weblocWithDesc:desc];
        
        url = [webloc url];
    }
    
    return url;
}

// returns nil if not a webloc, or not a server alias file at all
+ (NSAttributedString*)stringFromWeblocFile:(NTFileDesc*)desc;
{
    NSAttributedString* result=nil;
    
    if ([self isTextWeblocFile:desc])
    {
        NTWeblocFile* webloc = [self weblocWithDesc:desc];
        
        result = [webloc attributedString];
    }
    
    return result;
}

+ (BOOL)isTextWeblocFile:(NTFileDesc*)desc;
{
    if ([desc isFile] && ![desc isAlias])
    {
        if (([desc creator] == kWeblocFileCreator) || ([desc creator] == kDragWeblocType))
            return ([desc type] == kTEXTWeblocFileType);
    }
    
    return NO;
}

- (id)initWithDesc:(NTFileDesc*)desc;  // path to an existing webloc file
{
    self = [super init];

    if ([NTWeblocFile isHTTPWeblocFile:desc] || [NTWeblocFile isServerWeblocFile:desc])
        [self setURL:[NTWeblocFile extractUrlFromWeblocFile:desc]];
    else if ([NTWeblocFile isTextWeblocFile:desc])
        [self setString:[NTWeblocFile extractStringFromWeblocFile:desc]];

    [self setDisplayName:[desc displayName]];
    
    return self;
}

+ (id)weblocWithDesc:(NTFileDesc*)desc;
{
    NTWeblocFile* result = [[NTWeblocFile alloc] initWithDesc:desc];
        
    return [result autorelease];
}

// can be NSString or NSAttributedString
+ (id)weblocWithString:(id)string;
{
    NTWeblocFile* result = [[NTWeblocFile alloc] init];

    [result setString:string];

    return [result autorelease];
}

+ (id)weblocWithURL:(NSURL*)url;
{
    NTWeblocFile* result = [[NTWeblocFile alloc] init];
    
    [result setURL:url];

    return [result autorelease];
}

- (void)dealloc;
{
    [_url release];
    [_displayName release];
    [_attributedString release];
    
    [super dealloc];
}

- (BOOL)isHTTPWeblocFile;
{
    NSURL *url = [self url];
    
    if ([[url scheme] isEqualToString:@"http"] || [[url scheme] isEqualToString:@"https"])
        return YES;
    
    return NO;
}

- (BOOL)isServerWeblocFile;
{
    if ([self url])
    {
        if (![self isHTTPWeblocFile])
            return YES;
    }
    return NO;
}

- (NSURL*)url;
{
    return _url;
}

- (BOOL)isTextWeblocFile;
{
    return ([self attributedString] != nil);
}

- (NSAttributedString*)attributedString;
{
    return _attributedString;
}

// path includes filename
- (void)saveToFile:(NSString*)path;
{
    [self saveToFile:path hideExtension:YES];
}

- (void)saveToFile:(NSString*)path hideExtension:(BOOL)hideExtension;
{
    if (![NTPathUtilities pathOK:path])
    {
        // create a new file
        NTResourceFork* resource = [NTResourceFork resourceForkForWritingAtPath:path];
        NTFileDesc* desc = [NTFileDesc descNoResolve:path];
        NSMutableArray* entryArray = [NSMutableArray array];
        NSData* data;

        if ([desc isValid])
        {
            if (_url)
            {
                NSString* urlString = [_url absoluteString];
                
                // add the 'TEXT' resource
                data = [NSData dataWithBytes:[urlString UTF8String] length:strlen([urlString UTF8String])];
                [resource addData:data type:kTEXTWeblocType Id:256 name:nil];
                [entryArray addObject:[WLDragMapEntry entryWithType:kTEXTWeblocType resID:256]];

                // add the 'url ' resource
                [resource addData:data type:kURLWeblocType Id:256 name:nil];
                [entryArray addObject:[WLDragMapEntry entryWithType:kURLWeblocType resID:256]];

                // add the 'drag' resource
                [resource addData:[self dragDataWithEntries:entryArray] type:kDragWeblocType Id:128 name:nil];

                // set the type and creator
                if ([self isHTTPWeblocFile])
                    [NTFileModifier setType:kInternetLocationHTTP desc:desc];
                else
                    [NTFileModifier setType:kInternetLocationGeneric desc:desc];
				
                [NTFileModifier setCreator:kInternetLocationCreator desc:desc];
                
				// add url xml data to data fork
				NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:[_url absoluteString], @"URL", nil];
				NSString *error;				
				NSData* xmlData = [NSPropertyListSerialization dataFromPropertyList:dict
																			 format:NSPropertyListXMLFormat_v1_0
																   errorDescription:&error];
				if (xmlData)
					[xmlData writeToFile:path atomically:NO]; // NO because that would wipe the rsrc fork
								
                if (hideExtension)
                    [NTFileModifier setExtensionHidden:hideExtension desc:desc];
            }
            else if (_attributedString)
            {
                int length;

                // add the 'TEXT' resource
                data = [NSData dataWithBytes:[[_attributedString string] UTF8String] length:strlen([[_attributedString string] UTF8String])];
                [resource addData:data type:kTEXTWeblocType Id:256 name:nil];
                [entryArray addObject:[WLDragMapEntry entryWithType:kTEXTWeblocType resID:256]];

                // add the 'RTF ' resource
                data = [_attributedString RTFFromRange:NSMakeRange(0,[_attributedString length]) documentAttributes:nil];
                [resource addData:data type:kRTFWeblocType Id:256 name:nil];
                [entryArray addObject:[WLDragMapEntry entryWithType:kRTFWeblocType resID:256]];

                // add the 'utxt' resource
				const unsigned bufferSize = 1024*10;
                unichar buffer[bufferSize];
				length = MIN([_attributedString length], bufferSize);
                [[_attributedString string] getCharacters:buffer range:NSMakeRange(0, length)];
                data = [NSData dataWithBytes:buffer length:length*sizeof(unichar)];
                [resource addData:data type:kUnicodeWeblocType Id:256 name:nil];
                [entryArray addObject:[WLDragMapEntry entryWithType:kUnicodeWeblocType resID:256]];
				
				// add the 'utf8' resource
				const char* cPtr = [[_attributedString string] UTF8String];
                length = strlen(cPtr);
                data = [NSData dataWithBytes:cPtr length:length];
                [resource addData:data type:kUTF8WeblocType Id:256 name:nil];
                [entryArray addObject:[WLDragMapEntry entryWithType:kUTF8WeblocType resID:256]];
				
                // add the 'drag' resource
                [resource addData:[self dragDataWithEntries:entryArray] type:kDragWeblocType Id:128 name:nil];

                // set the type and creator
                [NTFileModifier setType:kTEXTWeblocFileType desc:desc];
                [NTFileModifier setCreator:kInternetLocationCreator desc:desc];
                
                if (hideExtension)
                    [NTFileModifier setExtensionHidden:hideExtension desc:desc];
            }
        }
	}
}

- (void)setDisplayName:(NSString*)name;
{
	[name retain];
    [_displayName release];
    _displayName = name;
}

- (NSString*)displayName;
{
    return _displayName;
}

@end

@implementation NTWeblocFile (Private)

- (void)setURL:(NSURL*)url;
{
	[url retain];
    [_url release];
    _url = url;
}

- (void)setString:(id)string;
{
    [_attributedString autorelease];

    // if a string, convert to attributed string
    if ([string isKindOfClass:[NSString class]])
        string = [[[NSAttributedString alloc] initWithString:string] autorelease];
    
    _attributedString = [string retain];
}

// extract the url from an existing file
+ (NSURL*)extractUrlFromWeblocFile:(NTFileDesc*)desc;
{
    NSArray* entries = [NTWeblocFile readEntriesFromWeblocFile:desc];
    WLDragMapEntry *entry;
    NSURL* url=nil;

    for (entry in entries)
    {
        if ([entry type] == kURLWeblocType)
        {            
            // now we know a url resource should exist, and we know the resID, so get the resource...
            NTResourceMgr* mgr = [NTResourceMgr mgrWithDesc:desc];
            NSData* data;
            
            data = [mgr resourceForType:kURLWeblocType resID:[entry resID]];
            if (data && [data length])
            {
                NSString* urlString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
                
                if ([urlString length])
                {
                    // [NSURL URLWithString] expects their string argument to contain any percent escape codes that are necessary
                    // urlString is already is percent escape format
                    // urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];

                    url = [NSURL URLWithString:urlString];
                }
            }      
            
            break;
        }
    }
    
    return url;
}

// extract the url from an existing file
+ (NSAttributedString*)extractStringFromWeblocFile:(NTFileDesc*)desc;
{
    NSAttributedString* attrString=nil;
    NSArray* entries = [NTWeblocFile readEntriesFromWeblocFile:desc];
    WLDragMapEntry *entry;
    BOOL done = NO;

    // first look for rtf code since it is styled
    if (!done)
    {
        NSEnumerator* enumerator = [entries objectEnumerator];

        while (!done && (entry = [enumerator nextObject]))
        {
            if ([entry type] == kRTFWeblocType)
            {
                // now we know a url resource should exist, and we know the resID, so get the resource...
                NTResourceMgr* mgr = [NTResourceMgr mgrWithDesc:desc];
                NSData* data = [mgr resourceForType:[entry type] resID:[entry resID]];

                if (data && [data length])
                    attrString = [[[NSAttributedString alloc] initWithRTF:data documentAttributes:nil] autorelease];
                
                done = YES;
            }
        }
    }

    // didn't find rtf, look for unicode
    if (!done)
    {
        NSEnumerator* enumerator = [entries objectEnumerator];

        while (!done && (entry = [enumerator nextObject]))
        {
            if ([entry type] == kUnicodeWeblocType)
            {
                // now we know a url resource should exist, and we know the resID, so get the resource...
                NTResourceMgr* mgr = [NTResourceMgr mgrWithDesc:desc];
                NSData* data = [mgr resourceForType:[entry type] resID:[entry resID]];

                if (data && [data length])
				{
					NSString* str = [[[NSString alloc] initWithData:data encoding:NSUnicodeStringEncoding] autorelease];
					
					if ([str length])
					{
						attrString = [[[NSAttributedString alloc] initWithString:str] autorelease];
						done = YES;
					}
				}
			}
        }
    }

    // didn't find unicode or rtf, look for plain text
    if (!done)
    {
        NSEnumerator* enumerator = [entries objectEnumerator];

        while (!done && (entry = [enumerator nextObject]))
        {
            if ([entry type] == kTEXTWeblocType)
            {
                // now we know a url resource should exist, and we know the resID, so get the resource...
                NTResourceMgr* mgr = [NTResourceMgr mgrWithDesc:desc];
                NSData* data = [mgr resourceForType:[entry type] resID:[entry resID]];

                if (data && [data length])
                    attrString = [[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:[data bytes] length:[data length]]] autorelease];

                done = YES;
            }
        }
    }
    
    return attrString;
}

+ (NSArray*)readEntriesFromWeblocFile:(NTFileDesc*)desc;
{
    NSMutableArray* result=nil;
    NTResourceMgr* mgr = [NTResourceMgr mgrWithDesc:desc];
    NSData* dragData = [mgr resourceForType:kDragWeblocType resID:128];

    if (dragData && [dragData length])
    {
        int totalLength=[dragData length];
        int offset=0;
        int dataLen;

        dataLen = sizeof(WLDragMapHeaderStruct);
        if ((offset + dataLen) <= totalLength)
        {
            WLDragMapHeaderStruct resHeader;
            int numEntries;

            // get resource header
            [dragData getBytes:&resHeader range:NSMakeRange(offset, dataLen)];

			// swap for intel
			[self swapWLDragMapHeader:&resHeader];

            // move the offset to the next entry
            offset += dataLen;

            numEntries = resHeader.numEntries;
            dataLen = sizeof(WLDragMapEntryStruct) * numEntries;

            if ((offset + dataLen) <= totalLength)
            {
                int i, cnt=numEntries;
                WLDragMapEntryStruct mapEntry;

                if (cnt)
                {
                    result = [NSMutableArray arrayWithCapacity:cnt];

                    dataLen = sizeof(WLDragMapEntryStruct);
                    for (i=0;i<cnt;i++)
                    {
                        [dragData getBytes:&mapEntry range:NSMakeRange(offset, dataLen)];

						// swap for intel
						[self swapWLDragMapEntry:&mapEntry];

                        offset += dataLen;

                        [result addObject:[WLDragMapEntry entryWithType:mapEntry.type resID:mapEntry.resID]];
                    }
                }
            }
        }
    }

    return result;
}

- (NSData*)dragDataWithEntries:(NSArray*)entries;
{
    NSMutableData *result;
    WLDragMapHeaderStruct header;
    WLDragMapEntry *entry;
    
    // zero the structure
    memset(&header, 0, sizeof(WLDragMapHeaderStruct));

    header.mapVersion = 1;
    header.numEntries = [entries count];

    result = [NSMutableData dataWithBytes:&header length:sizeof(WLDragMapHeaderStruct)];

    for (entry in entries)
        [result appendData:[entry entryData]];

    return result;
}

+ (void)swapWLDragMapHeader:(WLDragMapHeaderStruct*)map;
{
	/*
    long mapVersion;  // always 1
    long unused1;     // always 0
    long unused2;     // always 0
    short unused;
    short numEntries;   // number of repeating WLDragMapEntries
	 */
	
	map->mapVersion = NSSwapBigIntToHost(map->mapVersion);
	map->unused1 = NSSwapBigIntToHost(map->unused1);
	map->unused2 = NSSwapBigIntToHost(map->unused2);
	map->unused = NSSwapBigShortToHost(map->unused);
	map->numEntries = NSSwapBigShortToHost(map->numEntries);
}

+ (void)swapWLDragMapEntry:(WLDragMapEntryStruct*)entry;
{
	/*
    OSType type;
    short unused;  // always 0
    ResID resID;   // always 128 or 256?
    long unused1;   // always 0
    long unused2;   // always 0
	 */
	
	entry->type = NSSwapBigIntToHost(entry->type);
	entry->unused = NSSwapBigShortToHost(entry->unused);
	entry->resID = NSSwapBigShortToHost(entry->resID);
	entry->unused1 = NSSwapBigIntToHost(entry->unused1);
	entry->unused2 = NSSwapBigIntToHost(entry->unused2);
}

@end

// =================================================================================

@implementation WLDragMapEntry

- (id)initWithType:(OSType)type resID:(int)resID;
{
    self = [super init];

    _type = type;
    _resID = resID;

    return self;
}

+ (id)entryWithType:(OSType)type resID:(int)resID;
{
    WLDragMapEntry* result = [[WLDragMapEntry alloc] initWithType:type resID:resID];

    return [result autorelease];
}

- (OSType)type;
{
    return _type;
}

- (ResID)resID;
{
    return _resID;
}

- (NSData*)entryData;
{
    WLDragMapEntryStruct result;

    // zero the structure
    memset(&result, 0, sizeof(result));
    
    result.type = _type;
    result.resID = _resID;

    return [NSData dataWithBytes:&result length:sizeof(result)];
}

@end

