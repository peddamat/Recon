//
//  NTResourceMgr.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Tue Jul 23 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import "NTResourceMgr.h"
#import "NTResourceInfo.h"

// resource manager is not thread safe.  Here's a simple version that is
// http://developer.apple.com/techpubs/mac/MoreToolbox/MoreToolbox-99.html

#if PRAGMA_STRUCT_ALIGN
#pragma options align=mac68k
#elif PRAGMA_STRUCT_PACKPUSH
#pragma pack(push, 2)
#elif PRAGMA_STRUCT_PACK
#pragma pack(2)
#endif

typedef struct ResourceHeader
{
    int offsetToData;
    int offsetToMap;
    int dataLength;
    int mapLength;
} ResourceHeader;

typedef struct ResourceMap
{
    ResourceHeader headerCopy;
    Handle nextMap;
    short fileRef;
    short attributes;
    short offsetToTypeList;
    short offsetToNameList;
    short numberOfTypes;  // num types minus 1
                          // type list
                          // reference lists
                          // name list
} ResourceMap;

typedef struct ResourceType
{
    int type;
    short numResources;  // num resources minus 1
    short offsetToReferenceList;
} ResourceType;

typedef struct Resource
{
    short resourceID;
    short offsetToName;
    int offsetToData; // first byte is attributes (must & with 0x00FFFFFF to get offset)
    Handle handleToResource;
} Resource;

#if PRAGMA_STRUCT_ALIGN
#pragma options align=reset
#elif PRAGMA_STRUCT_PACKPUSH
#pragma pack(pop)
#elif PRAGMA_STRUCT_PACK
#pragma pack()
#endif

@interface NTResourceMgr (Private)
- (NSData*)fileData;
- (NSDictionary*)resourceMap;
- (NSData*)resourceForType:(OSType)resType resID:(int)resID matchResID:(BOOL)matchResID;

- (void)swapResource:(Resource*)resource;
- (void)swapResourceType:(ResourceType*)type;
- (void)swapResourceMap:(ResourceMap*)map;
- (void)swapResourceHeader:(ResourceHeader*)header;
@end

@implementation NTResourceMgr

- (id)initWithDesc:(NTFileDesc*)desc useDataFork:(BOOL)useDataFork;
{
    self = [super init];
    
    _desc = [desc retain];
    _useDataFork = useDataFork;
    _isValid = YES;

    // set valid to NO if can't read in a resource map
    if (![self resourceMap])
        _isValid = NO;
    
    return self;
}

+ (id)mgrWithDesc:(NTFileDesc*)desc useDataFork:(BOOL)useDataFork;
{
    NTResourceMgr* mgr = [[NTResourceMgr alloc] initWithDesc:desc useDataFork:useDataFork];

    return [mgr autorelease];
}

+ (id)mgrWithDesc:(NTFileDesc*)desc;
{
    return [self mgrWithDesc:desc useDataFork:NO];  // defaults to rsrc fork
}

- (void)dealloc;
{
    [_fileData release];
    [_desc release];
    [_resourceMap release];
    
    [super dealloc];
}

- (BOOL)isValid;  // returns no if wasn't able to read and parse the resource header
{
    return _isValid;
}

- (NSData*)resourceForType:(OSType)resType;
{
    return [self resourceForType:resType resID:0 matchResID:NO];
}

- (NSData*)resourceForType:(OSType)resType resID:(int)resID;
{
    return [self resourceForType:resType resID:resID matchResID:YES];
}

- (NSArray*)resourceTypes;
{
    NSDictionary* rsrcMap = [self resourceMap];
    if (rsrcMap)
        return [rsrcMap allKeys];

    return nil;
}

- (NSArray*)resouceIDsForType:(OSType)resType;
{
    NSDictionary* rsrcMap = [self resourceMap];
    if (rsrcMap)
    {
        NSDictionary* resources = [rsrcMap objectForKey:[NSNumber numberWithUnsignedInt:resType]];

        return [resources allKeys];
    }

    return nil;
}

- (NSArray*)resourceInfosForType:(OSType)resType;
{
    NSDictionary* rsrcMap = [self resourceMap];
    if (rsrcMap)
    {
        NSDictionary* resources = [rsrcMap objectForKey:[NSNumber numberWithUnsignedInt:resType]];

        return [resources allValues];
    }

    return nil;
}

@end

// =============================================================================

@implementation NTResourceMgr (Private)

- (NSData*)resourceForType:(OSType)resType resID:(int)resID matchResID:(BOOL)matchResID;
{
    NSData* result = nil;

    NSDictionary *rsrcMap = [self resourceMap];
    if (rsrcMap)
    {
        NSDictionary* resources = [rsrcMap objectForKey:[NSNumber numberWithUnsignedInt:resType]];

        if (resources)
        {
            NTResourceInfo *resourceInfo=nil;

            if (matchResID)
                resourceInfo = [resources objectForKey:[NSNumber numberWithUnsignedInt:resID]];
            else
            {
                // get the first resource in the list
                NSArray* values = [resources allValues];

                if ([values count])
                    resourceInfo = [values objectAtIndex:0];
            }

            if (resourceInfo)
                result = [[self fileData] subdataWithRange:NSMakeRange([resourceInfo offset], [resourceInfo size])];
        }
    }

    return result;
}

- (NSDictionary*)resourceMap;
{
    if (!_resourceMap && _isValid)
    {
        NSData* fileData = [self fileData];

        if (fileData)
        {
            NSMutableDictionary* map = nil;
            int totalLength=[fileData length];
            int offset=0;
            int dataLen;

            dataLen = sizeof(ResourceHeader);
            if ((offset + dataLen) <= totalLength)
            {
                ResourceHeader resHeader;

                // get resource header
                [fileData getBytes:&resHeader range:NSMakeRange(offset, dataLen)];

				// must swap bits for i386
				[self swapResourceHeader:&resHeader];
				
                // do a sanity check on the resHeader, this could be just junk in the resource fork
                if (resHeader.offsetToData > totalLength || resHeader.offsetToData < 0)
                    return nil;
                if (resHeader.offsetToMap > totalLength || resHeader.offsetToMap < 0)
                    return nil;
                if (resHeader.dataLength > totalLength || resHeader.dataLength < 0)
                    return nil;
                if (resHeader.mapLength > totalLength || resHeader.mapLength < 0)
                    return nil;
				
                // get the resource map
                dataLen = sizeof(ResourceMap);
                offset = resHeader.offsetToMap;
                if ((offset + dataLen) <= totalLength)
                {
                    ResourceMap resMap;
                    int numResTypes;
                    int resourceMapOffset = offset;

                    [fileData getBytes:&resMap range:NSMakeRange(offset, dataLen)];

					// must swap bits for i386
					[self swapResourceMap:&resMap];
					
                    numResTypes = (resMap.numberOfTypes+1);  // stored num-1, probably a speed optimization for the 128k mac
                    dataLen = sizeof(ResourceType) * numResTypes;
                    offset = resourceMapOffset + resMap.offsetToTypeList + 2;  // this offset points to the length
                    if ((offset + dataLen) <= totalLength)
                    {
                        int typeIndex, typeIndexCnt=numResTypes;
                        ResourceType resTypes[numResTypes];

                        [fileData getBytes:&resTypes range:NSMakeRange(offset, dataLen)];

						// must swap bits for i386						
						for (typeIndex=0;typeIndex<typeIndexCnt;typeIndex++)
							[self swapResourceType:(resTypes+typeIndex)];						
						
                        for (typeIndex=0;typeIndex<typeIndexCnt;typeIndex++)
                        {
                            int numResources = (resTypes[typeIndex].numResources+1); // stored num-1, probably a speed optimization for the 128k mac
                            dataLen = sizeof(Resource) * numResources;
                            offset = resTypes[typeIndex].offsetToReferenceList + resMap.offsetToTypeList + resourceMapOffset;
                            if ((offset + dataLen) <= totalLength)
                            {
                                NSMutableDictionary* resources = [NSMutableDictionary dictionary];
                                int rsrcIndex, rsrcCnt=numResources;
                                Resource rsrc[numResources];

                                [fileData getBytes:&rsrc range:NSMakeRange(offset, dataLen)];

								// must swap bits for i386
								for (rsrcIndex=0;rsrcIndex<rsrcCnt;rsrcIndex++)
									[self swapResource:(rsrc+rsrcIndex)];

                                for (rsrcIndex=0;rsrcIndex<rsrcCnt;rsrcIndex++)
                                {
									UInt32 mask = 0x00FFFFFF;
                                    offset = resHeader.offsetToData + (rsrc[rsrcIndex].offsetToData & mask);
                                    dataLen = 4;

                                    if ((offset + dataLen) <= totalLength)
                                    {
                                        // length is first int at offset
                                        [fileData getBytes:&dataLen range:NSMakeRange(offset, dataLen)];

										// must swap bits for i386
										dataLen = NSSwapBigIntToHost(dataLen);
										
                                        offset += 4;
                                        if ((offset + dataLen) <= totalLength)
                                        {
                                            NSString *rsrcName = nil;

                                            // does the resource have a name?
                                            if (rsrc[rsrcIndex].offsetToName != -1)
                                            {
                                                int nameOffset = resourceMapOffset + resMap.offsetToNameList + rsrc[rsrcIndex].offsetToName;  // this offset points to the length
                                                unsigned char len;
												unsigned nameLength;

												// a one byte length for the pascal string name, no swapping needed
                                                [fileData getBytes:&len range:NSMakeRange(nameOffset, sizeof(char))];
												nameLength = (unsigned)len;
												
												// max len is 255
                                                if ((nameLength >= 0) && (nameLength < 256))
                                                {
                                                    unsigned char name[256];

                                                    [fileData getBytes:name range:NSMakeRange(nameOffset, nameLength+1)];

                                                    rsrcName = [NSString stringWithUTF8String:name+1 length:name[0]];
                                                }
                                            }
                                                
                                            NTResourceInfo *info = [NTResourceInfo resourceInfoForType:resTypes[typeIndex].type resID:rsrc[rsrcIndex].resourceID name:rsrcName offset:offset size:dataLen];

                                            [resources setObject:info forKey:[NSNumber numberWithInt:rsrc[rsrcIndex].resourceID]];
                                        }
                                    }
                                }

                                if (!map)
                                    map = [NSMutableDictionary dictionary];

                                [map setObject:resources forKey:[NSNumber numberWithUnsignedInt:resTypes[typeIndex].type]];
                            }
                        }
                    }
                }
            }

            if (map)
                _resourceMap = [[NSDictionary alloc] initWithDictionary:map];            
        }
    }

    return _resourceMap;
}

- (NSData*)fileData;
{
    if (!_fileData)
    {
        // do a bunch of checks here before we read the file

        // first make sure it's a file
        if ([_desc isFile])
        {
			NSData* data = [NSData resourceData:_desc rsrcFork:!_useDataFork];
			
			if (data && [data length])
				_fileData = [data retain];
        }
    }
	
    return _fileData;
}

- (void)swapResourceHeader:(ResourceHeader*)header;
{
	/*
	 int offsetToData;
	 int offsetToMap;
	 int dataLength;
	 int mapLength;
	 */	
	
	header->offsetToData = NSSwapBigIntToHost(header->offsetToData);
	header->offsetToMap = NSSwapBigIntToHost(header->offsetToMap);
	header->dataLength = NSSwapBigIntToHost(header->dataLength);
	header->mapLength = NSSwapBigIntToHost(header->mapLength);
}

- (void)swapResourceMap:(ResourceMap*)map;
{
	/*
	 ResourceHeader headerCopy;
	 Handle nextMap;
	 short fileRef;
	 short attributes;
	 short offsetToTypeList;
	 short offsetToNameList;
	 short numberOfTypes;  // num types minus 1
						   // type list
						   // reference lists
						   // name list
	 */
	
	map->fileRef = NSSwapBigShortToHost(map->fileRef);
	map->attributes = NSSwapBigShortToHost(map->attributes);
	map->offsetToTypeList = NSSwapBigShortToHost(map->offsetToTypeList);
	map->offsetToNameList = NSSwapBigShortToHost(map->offsetToNameList);
	map->numberOfTypes = NSSwapBigShortToHost(map->numberOfTypes);
}


- (void)swapResourceType:(ResourceType*)type;
{
	/*
	 int type;
	 short numResources;  // num resources minus 1
	 short offsetToReferenceList;
	 */
	
	type->type = NSSwapBigIntToHost(type->type);
	type->numResources = NSSwapBigShortToHost(type->numResources);
	type->offsetToReferenceList = NSSwapBigShortToHost(type->offsetToReferenceList);
}

- (void)swapResource:(Resource*)resource;
{
	/*
	 short resourceID;
	 short offsetToName;
	 int offsetToData; // first byte is attributes (must & with 0x00FFFFFF to get offset)
	 Handle handleToResource;
	 */
	
	resource->resourceID = NSSwapBigShortToHost(resource->resourceID);
	resource->offsetToName = NSSwapBigShortToHost(resource->offsetToName);
	resource->offsetToData = NSSwapBigIntToHost(resource->offsetToData);
}

@end

// =======================================================================================
// =======================================================================================

@interface NSData (ResourceForkAdditionsPrivate)
+ (SInt16)openRsrcFile:(NTFileDesc*)desc rsrcFork:(BOOL)rsrcFork;
+ (void)closeRsrcFile:(SInt16)fileRefNum;
@end

@implementation NSData (ResourceForkAdditions)

// Reading the fork automatically handles the ._ files (their in apple double format)

+ (NSData*)resourceData:(NTFileDesc*)file rsrcFork:(BOOL)rsrcFork;
{
	SInt16 fileRefNum = [self openRsrcFile:file rsrcFork:rsrcFork];
	NSData* result = nil;
	
	if (fileRefNum)
	{
		int numBytes = 0;
		
		if (rsrcFork)
			numBytes = [file rsrcForkSize];
		else
			numBytes = [file dataForkSize];
			
		ByteCount actualCount;
		unsigned char *buffer = malloc(numBytes);
		
		OSErr err = FSReadFork(fileRefNum, fsFromStart + noCacheMask, 0, numBytes, buffer, &actualCount);
		
		// this error is fine, ignore
		if (err == eofErr)
			err = noErr;
		
		if (!err && actualCount)
			result = [NSData dataWithBytes:buffer length:actualCount];
		
		free(buffer);
	}
	
	[self closeRsrcFile:fileRefNum];
	
	return result;
}

@end

@implementation NSData (ResourceForkAdditionsPrivate)

+ (void)closeRsrcFile:(SInt16)refNum;
{
	if (refNum)
        FSCloseFork(refNum);
}

+ (SInt16)openRsrcFile:(NTFileDesc*)file rsrcFork:(BOOL)rsrcFork;
{
	FSIORefNum refNum=0;
	
	HFSUniStr255 forkName;
	
	if (rsrcFork)
		FSGetResourceForkName(&forkName);
	else
		FSGetDataForkName(&forkName);
	
	OSErr err = FSOpenFork([file FSRefPtr], forkName.length, forkName.unicode, fsRdPerm, &refNum);
	if (err != noErr)
		refNum = 0;
	
	return refNum;
}

@end
