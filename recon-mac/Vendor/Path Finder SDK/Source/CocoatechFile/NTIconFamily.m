// NTIconFamily.m
// NTIconFamily class implementation

#import "NTIconFamily.h"
#import "NTIcon.h"
#import "NTVolumeNotificationMgr.h"
#import "NTPathUtilities.h"
#import "NTFSWatcher.h"

@interface NTIconFamily (Internals)
+ (Handle)get32BitDataFromBitmapImageRep:(NSBitmapImageRep*)bitmapImageRep requiredPixelSize:(int)requiredPixelSize;
+ (Handle)get8BitDataFromBitmapImageRep:(NSBitmapImageRep*)bitmapImageRep requiredPixelSize:(int)requiredPixelSize;
+ (Handle)get8BitMaskFromBitmapImageRep:(NSBitmapImageRep*)bitmapImageRep requiredPixelSize:(int)requiredPixelSize;
+ (Handle)get1BitMaskFromBitmapImageRep:(NSBitmapImageRep*)bitmapImageRep requiredPixelSize:(int)requiredPixelSize;
- (BOOL)addResourceType:(OSType)type asResID:(int)resID;
- (BOOL)setAsCustomIconForVolume:(NTFileDesc*)path;
+ (BOOL)removeCustomIconFromVolume:(NTFileDesc*)path;
- (void)buildWithImage:(NSImage*)image;
- (BOOL)setIconFamilyElement:(OSType)elementType
		  fromBitmapImageRep:(NSBitmapImageRep*)bitmapImageRep;
@end

@interface NTIconFamily (hidden)
- (void)setIconFamilyHandle:(IconFamilyHandle)theIconFamilyHandle;
@end

@implementation NTIconFamily

+ (NTIconFamily*)iconFamilyWithIconOfFile:(NTFileDesc*)desc
{
	IconFamilyHandle handle;
    OSErr err = IconRefToIconFamily([[desc icon] iconRef],
									kSelectorAllAvailableData,
									&handle);
	if (!err)
		return [self iconFamilyWithHandle:handle];
	
	return nil;
}

+ (NTIconFamily*)iconFamilyWithHandle:(IconFamilyHandle)handle;
{
	NTIconFamily* result = [[NTIconFamily alloc] init];
	
	[result setIconFamilyHandle:handle];
	
	return [result autorelease];
}

+ (NTIconFamily*)iconFamilyWithImage:(NSImage*)image
{
	NTIconFamily* result = [[NTIconFamily alloc] init];
	
    [result buildWithImage:image];
	
	return [result autorelease];
}

- (void)dealloc
{
    [self setIconFamilyHandle:nil];
	
    [super dealloc];
}

//---------------------------------------------------------- 
//  iconFamilyHandle 
//---------------------------------------------------------- 
- (IconFamilyHandle)iconFamilyHandle
{
	if (!mIconFamilyHandle)
		mIconFamilyHandle = (IconFamilyHandle) NewHandle(0);
	
    return mIconFamilyHandle;
}

- (void)setIconFamilyHandle:(IconFamilyHandle)theIconFamilyHandle
{
    if (mIconFamilyHandle != theIconFamilyHandle)
    {
        DisposeHandle((Handle) mIconFamilyHandle);
		
        mIconFamilyHandle = theIconFamilyHandle;
    }
}

- (NSImage*)image;
{
    return [[[NSImage alloc] initWithData:[NSData dataWithBytes:*[self iconFamilyHandle] length:GetHandleSize((Handle)[self iconFamilyHandle])]] autorelease];
}

- (BOOL)setAsCustomIconForFile:(NTFileDesc*)desc;
{
	BOOL result = [[NSWorkspace sharedWorkspace] setIcon:[self image] forFile:[desc path] options:NSExclude10_4ElementsIconCreationOption];
	
	if (!result)
		NSLog(@"custom icon not set");
	
    return YES;
}

+ (BOOL)removeCustomIconFromFile:(NTFileDesc*)desc
{
	[[NSWorkspace sharedWorkspace] setIcon:nil forFile:[desc path] options:0];
	
    return YES;
}

+ (BOOL)removeCustomIconFromDirectory:(NTFileDesc*)desc;
{
    if ([desc isValid] && [desc isDirectory])
    {
        if ([desc isVolume])
            return [NTIconFamily removeCustomIconFromVolume:desc];
        else
			[[NSWorkspace sharedWorkspace] setIcon:nil forFile:[desc path] options:0];
		
        return YES;
    }

    return NO;
}

- (BOOL)setAsCustomIconForDirectory:(NTFileDesc*)desc;
{
    if ([desc isValid] && [desc isDirectory])
    {
        if ([desc isVolume])
            return [self setAsCustomIconForVolume:desc];
        else
			[[NSWorkspace sharedWorkspace] setIcon:[self image] forFile:[desc path] options:0];

        return YES;
    }

    return NO;
}

- (BOOL)writeToFile:(NSString*)path
{
    NSData* data = NULL;

    data = [NSData dataWithCarbonHandle:(Handle)[self iconFamilyHandle]];
	if (data)
		[data writeToFile:path atomically:NO];

    return YES;
}

+ (BOOL)hasCustomIconForFile:(NTFileDesc*)desc
{
    FSRef parentDirectoryFSRef;
    SInt16 file;
    OSErr result;
    Handle hExistingCustomIcon;
    BOOL hasCustomIcon=NO;

    result = FSGetCatalogInfo( [desc FSRefPtr], kFSCatInfoNone, NULL, NULL, NULL, &parentDirectoryFSRef );
    if (result != noErr)
        return NO;

    // Open the file's resource fork, if it has one.
    file = FSOpenResFile( [desc FSRefPtr], fsRdWrPerm );
    if (file == -1)
        return NO;

    // Remove the file's existing kCustomIconResource of type kIconFamilyType
    // (if any).
    hExistingCustomIcon = GetResource( kIconFamilyType, kCustomIconResource );
    if( hExistingCustomIcon )
    {
        ReleaseResource( hExistingCustomIcon );

        // found the resource, so assume it has a custom icon
        hasCustomIcon = YES;
    }

    // Close the file's resource fork, flushing the resource map out to disk.
    CloseResFile( file );

    return hasCustomIcon;
}

+ (BOOL)hasCustomIconForDirectory:(NTFileDesc*)desc;
{
    BOOL isDir;
    BOOL exists;
    NSString *iconrPath = [[desc path] stringByAppendingPathComponent:@"Icon\r"];

    exists = [[NSFileManager defaultManager] fileExistsAtPath:[desc path] isDirectory:&isDir];

    if( !isDir || !exists )
        return NO;

    if( [[NSFileManager defaultManager] fileExistsAtPath:iconrPath] )
        return YES;

    return NO;
}

// this tells the IconRef database that we have changed, need to update
+ (void)updateIconRef:(NTFileDesc*)desc;
{
    NTIcon* ntIcon = [desc icon];

    if (ntIcon)
        UpdateIconRef([ntIcon iconRef]);
}

@end

@implementation NTIconFamily (Internals)

+ (Handle)get32BitDataFromBitmapImageRep:(NSBitmapImageRep*)bitmapImageRep requiredPixelSize:(int)requiredPixelSize
{
    Handle hRawData;
    unsigned char* pRawData;
    Size rawDataSize;
    unsigned char* pSrc;
    unsigned char* pDest;
    int x, y;
    unsigned char alphaByte;
    float oneOverAlpha;

    // Get information about the bitmapImageRep.
    int pixelsWide      = [bitmapImageRep pixelsWide];
    int pixelsHigh      = [bitmapImageRep pixelsHigh];
    int bitsPerSample   = [bitmapImageRep bitsPerSample];
    int samplesPerPixel = [bitmapImageRep samplesPerPixel];
    int bitsPerPixel    = [bitmapImageRep bitsPerPixel];
    //    BOOL hasAlpha       = [bitmapImageRep hasAlpha];
    BOOL isPlanar       = [bitmapImageRep isPlanar];
    //    int numberOfPlanes  = [bitmapImageRep numberOfPlanes];
    int bytesPerRow     = [bitmapImageRep bytesPerRow];
    //    int bytesPerPlane   = [bitmapImageRep bytesPerPlane];
    unsigned char* bitmapData = [bitmapImageRep bitmapData];

    // Make sure bitmap has the required dimensions.
    if (pixelsWide != requiredPixelSize || pixelsHigh != requiredPixelSize)
        return NULL;

    // So far, this code only handles non-planar 32-bit RGBA and 24-bit RGB source bitmaps.
    // This could be made more flexible with some additional programming to accommodate other possible
    // formats...
    if (isPlanar)
    {
        NSLog(@"get32BitDataFromBitmapImageRep:requiredPixelSize: returning NULL due to isPlanar == YES");
        return NULL;
    }
    if (bitsPerSample != 8)
    {
        NSLog(@"get32BitDataFromBitmapImageRep:requiredPixelSize: returning NULL due to bitsPerSample == %d", bitsPerSample);
        return NULL;
    }

    if (((samplesPerPixel == 3) && (bitsPerPixel == 24)) || ((samplesPerPixel == 4) && (bitsPerPixel == 32)))
    {
        rawDataSize = pixelsWide * pixelsHigh * 4;
        hRawData = NewHandle( rawDataSize );
        if (hRawData == NULL)
            return NULL;
        pRawData = (unsigned char*) *hRawData;

        pSrc = bitmapData;
        pDest = pRawData;

        if (bitsPerPixel == 32) {
            for (y = 0; y < pixelsHigh; y++) {
                pSrc = bitmapData + y * bytesPerRow;
                for (x = 0; x < pixelsWide; x++) {
                    // Each pixel is 3 bytes of RGB data, followed by 1 byte of
                    // alpha.  The RGB values are premultiplied by the alpha (so
                    // that Quartz can save time when compositing the bitmap to a
                    // destination), and we undo this premultiplication (with some
                    // lossiness unfortunately) when retrieving the bitmap data.
                    *pDest++ = alphaByte = *(pSrc+3);
                    if (alphaByte) {
                        oneOverAlpha = 255.0f / (float)alphaByte;
                        *pDest++ = *(pSrc+0) * oneOverAlpha;
                        *pDest++ = *(pSrc+1) * oneOverAlpha;
                        *pDest++ = *(pSrc+2) * oneOverAlpha;
                    } else {
                        *pDest++ = 0;
                        *pDest++ = 0;
                        *pDest++ = 0;
                    }
                    pSrc+=4;
                }
            }
        } else if (bitsPerPixel == 24) {
            for (y = 0; y < pixelsHigh; y++) {
                pSrc = bitmapData + y * bytesPerRow;
                for (x = 0; x < pixelsWide; x++) {
                    *pDest++ = 0;
                    *pDest++ = *pSrc++;
                    *pDest++ = *pSrc++;
                    *pDest++ = *pSrc++;
                }
            }
        }
    }
    else
    {
        NSLog(@"get32BitDataFromBitmapImageRep:requiredPixelSize: returning NULL due to samplesPerPixel == %d, bitsPerPixel == %", samplesPerPixel, bitsPerPixel);
        return NULL;
    }

    return hRawData;
}

+ (Handle)get8BitDataFromBitmapImageRep:(NSBitmapImageRep*)bitmapImageRep requiredPixelSize:(int)requiredPixelSize
{
    Handle hRawData;
    unsigned char* pRawData;
    Size rawDataSize;
    unsigned char* pSrc;
    unsigned char* pDest;
    int x, y;

    // Get information about the bitmapImageRep.
    int pixelsWide      = [bitmapImageRep pixelsWide];
    int pixelsHigh      = [bitmapImageRep pixelsHigh];
    int bitsPerSample   = [bitmapImageRep bitsPerSample];
    int samplesPerPixel = [bitmapImageRep samplesPerPixel];
    int bitsPerPixel    = [bitmapImageRep bitsPerPixel];
    BOOL isPlanar       = [bitmapImageRep isPlanar];
    int bytesPerRow     = [bitmapImageRep bytesPerRow];
    unsigned char* bitmapData = [bitmapImageRep bitmapData];

    // Make sure bitmap has the required dimensions.
    if (pixelsWide != requiredPixelSize || pixelsHigh != requiredPixelSize)
        return NULL;

    // So far, this code only handles non-planar 32-bit RGBA and 24-bit RGB source bitmaps.
    // This could be made more flexible with some additional programming...
    if (isPlanar)
    {
        NSLog(@"get8BitDataFromBitmapImageRep:requiredPixelSize: returning NULL due to isPlanar == YES");
        return NULL;
    }
    if (bitsPerSample != 8)
    {
        NSLog(@"get8BitDataFromBitmapImageRep:requiredPixelSize: returning NULL due to bitsPerSample == %d", bitsPerSample);
        return NULL;
    }

    if (((samplesPerPixel == 3) && (bitsPerPixel == 24)) || ((samplesPerPixel == 4) && (bitsPerPixel == 32)))
    {
        CGDirectPaletteRef cgPal;
        CGDeviceColor cgCol;

        rawDataSize = pixelsWide * pixelsHigh;
        hRawData = NewHandle( rawDataSize );
        if (hRawData == NULL)
            return NULL;
        pRawData = (unsigned char*) *hRawData;

        cgPal = CGPaletteCreateDefaultColorPalette();

        pSrc = bitmapData;
        pDest = pRawData;
        if (bitsPerPixel == 32) {
            for (y = 0; y < pixelsHigh; y++) {
                pSrc = bitmapData + y * bytesPerRow;
                for (x = 0; x < pixelsWide; x++) {
                    cgCol.red = ((float)*(pSrc)) / 255;
                    cgCol.green = ((float)*(pSrc+1)) / 255;
                    cgCol.blue = ((float)*(pSrc+2)) / 255;

                    *pDest++ = CGPaletteGetIndexForColor(cgPal, cgCol);

                    pSrc+=4;
                }
            }
        } else if (bitsPerPixel == 24) {
            for (y = 0; y < pixelsHigh; y++) {
                pSrc = bitmapData + y * bytesPerRow;
                for (x = 0; x < pixelsWide; x++) {
                    cgCol.red = ((float)*(pSrc)) / 255;
                    cgCol.green = ((float)*(pSrc+1)) / 255;
                    cgCol.blue = ((float)*(pSrc+2)) / 255;

                    *pDest++ = CGPaletteGetIndexForColor(cgPal, cgCol);

                    pSrc+=3;
                }
            }
        }

        CGPaletteRelease(cgPal);
    }
    else
    {
        NSLog(@"get8BitDataFromBitmapImageRep:requiredPixelSize: returning NULL due to samplesPerPixel == %d, bitsPerPixel == %", samplesPerPixel, bitsPerPixel);
        return NULL;
    }

    return hRawData;
}

+ (Handle)get8BitMaskFromBitmapImageRep:(NSBitmapImageRep*)bitmapImageRep requiredPixelSize:(int)requiredPixelSize
{
    Handle hRawData;
    unsigned char* pRawData;
    Size rawDataSize;
    unsigned char* pSrc;
    unsigned char* pDest;
    int x, y;

    // Get information about the bitmapImageRep.
    int pixelsWide      = [bitmapImageRep pixelsWide];
    int pixelsHigh      = [bitmapImageRep pixelsHigh];
    int bitsPerSample   = [bitmapImageRep bitsPerSample];
    int samplesPerPixel = [bitmapImageRep samplesPerPixel];
    int bitsPerPixel    = [bitmapImageRep bitsPerPixel];
    //    BOOL hasAlpha       = [bitmapImageRep hasAlpha];
    BOOL isPlanar       = [bitmapImageRep isPlanar];
    //    int numberOfPlanes  = [bitmapImageRep numberOfPlanes];
    int bytesPerRow     = [bitmapImageRep bytesPerRow];
    //    int bytesPerPlane   = [bitmapImageRep bytesPerPlane];
    unsigned char* bitmapData = [bitmapImageRep bitmapData];

    // Make sure bitmap has the required dimensions.
    if (pixelsWide != requiredPixelSize || pixelsHigh != requiredPixelSize)
        return NULL;

    // So far, this code only handles non-planar 32-bit RGBA, 24-bit RGB and 8-bit grayscale source bitmaps.
    // This could be made more flexible with some additional programming...
    if (isPlanar)
    {
        NSLog(@"get8BitMaskFromBitmapImageRep:requiredPixelSize: returning NULL due to isPlanar == YES");
        return NULL;
    }
    if (bitsPerSample != 8)
    {
        NSLog(@"get8BitMaskFromBitmapImageRep:requiredPixelSize: returning NULL due to bitsPerSample == %d", bitsPerSample);
        return NULL;
    }

    if (((samplesPerPixel == 1) && (bitsPerPixel == 8)) || ((samplesPerPixel == 3) && (bitsPerPixel == 24)) || ((samplesPerPixel == 4) && (bitsPerPixel == 32)))
    {
        rawDataSize = pixelsWide * pixelsHigh;
        hRawData = NewHandle( rawDataSize );
        if (hRawData == NULL)
            return NULL;
        pRawData = (unsigned char*) *hRawData;

        pSrc = bitmapData;
        pDest = pRawData;

        if (bitsPerPixel == 32) {
            for (y = 0; y < pixelsHigh; y++) {
                pSrc = bitmapData + y * bytesPerRow;
                for (x = 0; x < pixelsWide; x++) {
                    pSrc += 3;
                    *pDest++ = *pSrc++;
                }
            }
        }
        else if (bitsPerPixel == 24) {
            memset( pDest, 255, rawDataSize );
        }
        else if (bitsPerPixel == 8) {
            for (y = 0; y < pixelsHigh; y++) {
                memcpy( pDest, pSrc, pixelsWide );
                pSrc += bytesPerRow;
                pDest += pixelsWide;
            }
        }
    }
    else
    {
        NSLog(@"get8BitMaskFromBitmapImageRep:requiredPixelSize: returning NULL due to samplesPerPixel == %d, bitsPerPixel == %", samplesPerPixel, bitsPerPixel);
        return NULL;
    }

    return hRawData;
}

// NOTE: This method hasn't been fully tested yet.
+ (Handle)get1BitMaskFromBitmapImageRep:(NSBitmapImageRep*)bitmapImageRep requiredPixelSize:(int)requiredPixelSize
{
    Handle hRawData;
    unsigned char* pRawData;
    Size rawDataSize;
    unsigned char* pSrc;
    unsigned char* pDest;
    int x, y;
    unsigned char maskByte;

    // Get information about the bitmapImageRep.
    int pixelsWide      = [bitmapImageRep pixelsWide];
    int pixelsHigh      = [bitmapImageRep pixelsHigh];
    int bitsPerSample   = [bitmapImageRep bitsPerSample];
    int samplesPerPixel = [bitmapImageRep samplesPerPixel];
    int bitsPerPixel    = [bitmapImageRep bitsPerPixel];
    //    BOOL hasAlpha       = [bitmapImageRep hasAlpha];
    BOOL isPlanar       = [bitmapImageRep isPlanar];
    //    int numberOfPlanes  = [bitmapImageRep numberOfPlanes];
    int bytesPerRow     = [bitmapImageRep bytesPerRow];
    //    int bytesPerPlane   = [bitmapImageRep bytesPerPlane];
    unsigned char* bitmapData = [bitmapImageRep bitmapData];

    // Make sure bitmap has the required dimensions.
    if (pixelsWide != requiredPixelSize || pixelsHigh != requiredPixelSize)
        return NULL;

    // So far, this code only handles non-planar 32-bit RGBA, 24-bit RGB, 8-bit grayscale, and 1-bit source bitmaps.
    // This could be made more flexible with some additional programming...
    if (isPlanar)
    {
        NSLog(@"get1BitMaskFromBitmapImageRep:requiredPixelSize: returning NULL due to isPlanar == YES");
        return NULL;
    }

    if (((bitsPerPixel == 1) && (samplesPerPixel == 1) && (bitsPerSample == 1)) || ((bitsPerPixel == 8) && (samplesPerPixel == 1) && (bitsPerSample == 8)) ||
        ((bitsPerPixel == 24) && (samplesPerPixel == 3) && (bitsPerSample == 8)) || ((bitsPerPixel == 32) && (samplesPerPixel == 4) && (bitsPerSample == 8)))
    {
        rawDataSize = (pixelsWide * pixelsHigh)/4;
        hRawData = NewHandle( rawDataSize );
        if (hRawData == NULL)
            return NULL;
        pRawData = (unsigned char*) *hRawData;

        pSrc = bitmapData;
        pDest = pRawData;

        if (bitsPerPixel == 32) {
            for (y = 0; y < pixelsHigh; y++) {
                pSrc = bitmapData + y * bytesPerRow;
                for (x = 0; x < pixelsWide; x += 8) {
                    maskByte = 0;
                    maskByte |= (*(unsigned*)pSrc & 0xff) ? 0x80 : 0; pSrc += 4;
                    maskByte |= (*(unsigned*)pSrc & 0xff) ? 0x40 : 0; pSrc += 4;
                    maskByte |= (*(unsigned*)pSrc & 0xff) ? 0x20 : 0; pSrc += 4;
                    maskByte |= (*(unsigned*)pSrc & 0xff) ? 0x10 : 0; pSrc += 4;
                    maskByte |= (*(unsigned*)pSrc & 0xff) ? 0x08 : 0; pSrc += 4;
                    maskByte |= (*(unsigned*)pSrc & 0xff) ? 0x04 : 0; pSrc += 4;
                    maskByte |= (*(unsigned*)pSrc & 0xff) ? 0x02 : 0; pSrc += 4;
                    maskByte |= (*(unsigned*)pSrc & 0xff) ? 0x01 : 0; pSrc += 4;
                    *pDest++ = maskByte;
                }
            }
        }
        else if (bitsPerPixel == 24) {
            memset( pDest, 255, rawDataSize );
        }
        else if (bitsPerPixel == 8) {
            for (y = 0; y < pixelsHigh; y++) {
                pSrc = bitmapData + y * bytesPerRow;
                for (x = 0; x < pixelsWide; x += 8) {
                    maskByte = 0;
                    maskByte |= *pSrc++ ? 0x80 : 0;
                    maskByte |= *pSrc++ ? 0x40 : 0;
                    maskByte |= *pSrc++ ? 0x20 : 0;
                    maskByte |= *pSrc++ ? 0x10 : 0;
                    maskByte |= *pSrc++ ? 0x08 : 0;
                    maskByte |= *pSrc++ ? 0x04 : 0;
                    maskByte |= *pSrc++ ? 0x02 : 0;
                    maskByte |= *pSrc++ ? 0x01 : 0;
                    *pDest++ = maskByte;
                }
            }
        }
        else if (bitsPerPixel == 1) {
            for (y = 0; y < pixelsHigh; y++) {
                memcpy( pDest, pSrc, pixelsWide / 8 );
                pDest += pixelsWide / 8;
                pSrc += bytesPerRow;
            }
        }

        memcpy( pRawData+(pixelsWide*pixelsHigh)/8, pRawData, (pixelsWide*pixelsHigh)/8 );
    }
    else
    {
        NSLog(@"get1BitMaskFromBitmapImageRep:requiredPixelSize: returning NULL due to bitsPerPixel == %d, samplesPerPixel== %d, bitsPerSample == %d", bitsPerPixel, samplesPerPixel, bitsPerSample);
        return NULL;
    }

    return hRawData;
}

- (BOOL)addResourceType:(OSType)type asResID:(int)resID
{
    Handle hIconRes = NewHandle(0);
    OSErr err;

    err = GetIconFamilyData( [self iconFamilyHandle], type, hIconRes );

    if( !GetHandleSize(hIconRes) || err != noErr )
        return NO;

    AddResource( hIconRes, type, resID, "\p" );

    return YES;
}

- (BOOL)setAsCustomIconForVolume:(NTFileDesc*)desc;
{
    // filename for custom icon is ".VolumeIcon.icns"
    NSString *iconPath = [[desc path] stringByAppendingPathComponent:@".VolumeIcon.icns"];

    // remove any existing file first.
    [NTIconFamily removeCustomIconFromVolume:desc];

    [self writeToFile:iconPath];
    FSSetHasCustomIcon([desc FSRefPtr]);

    // rebuild volumeList
    [[NTVolumeNotificationMgr sharedInstance] manuallyRefresh];

    return YES;
}

- (void)buildWithImage:(NSImage*)image;
{
    NSBitmapImageRep* bitmap;
		
    bitmap = [image bitmapImageRepForSize:128];
    if (bitmap) 
	{
        [self setIconFamilyElement:kThumbnail32BitData fromBitmapImageRep:bitmap];
        [self setIconFamilyElement:kThumbnail8BitMask  fromBitmapImageRep:bitmap];
    }
	
    bitmap = [image bitmapImageRepForSize:32];
    if (bitmap) 
	{
        [self setIconFamilyElement:kLarge32BitData fromBitmapImageRep:bitmap];
        [self setIconFamilyElement:kLarge8BitData fromBitmapImageRep:bitmap];
        [self setIconFamilyElement:kLarge8BitMask fromBitmapImageRep:bitmap];
        [self setIconFamilyElement:kLarge1BitMask fromBitmapImageRep:bitmap];
    }
	
    bitmap = [image bitmapImageRepForSize:16];
    if (bitmap) 
	{
        [self setIconFamilyElement:kSmall32BitData fromBitmapImageRep:bitmap];
        [self setIconFamilyElement:kSmall8BitData fromBitmapImageRep:bitmap];
        [self setIconFamilyElement:kSmall8BitMask fromBitmapImageRep:bitmap];
        [self setIconFamilyElement:kSmall1BitMask fromBitmapImageRep:bitmap];
    }
}

+ (BOOL)removeCustomIconFromVolume:(NTFileDesc*)desc;
{
    // filename for custom icon is ".VolumeIcon.icns"
    NSString *iconPath = [[desc path] stringByAppendingPathComponent:@".VolumeIcon.icns"];

    if( [[NSFileManager defaultManager] fileExistsAtPath:iconPath] )
    {
        if( ![[NSFileManager defaultManager] removeItemAtPath:iconPath error:nil] )
            return NO;

        FSClearHasCustomIcon([desc FSRefPtr]);
        [NTIconFamily updateIconRef:desc];

        // rebuild volumeList
		[[NTVolumeNotificationMgr sharedInstance] manuallyRefresh];
    }

    return YES;
}

- (BOOL)setIconFamilyElement:(OSType)elementType fromBitmapImageRep:(NSBitmapImageRep*)bitmapImageRep
{
    Handle hRawData = NULL;
    OSErr result;
	
    switch (elementType) {
			// 'it32' 128x128 32-bit RGB image
        case kThumbnail32BitData:
            hRawData = [NTIconFamily get32BitDataFromBitmapImageRep:bitmapImageRep requiredPixelSize:128];
            break;
			
            // 't8mk' 128x128 8-bit alpha mask
        case kThumbnail8BitMask:
            hRawData = [NTIconFamily get8BitMaskFromBitmapImageRep:bitmapImageRep requiredPixelSize:128];
            break;
			
            // 'il32' 32x32 32-bit RGB image
        case kLarge32BitData:
            hRawData = [NTIconFamily get32BitDataFromBitmapImageRep:bitmapImageRep requiredPixelSize:32];
            break;
			
            // 'l8mk' 32x32 8-bit alpha mask
        case kLarge8BitMask:
            hRawData = [NTIconFamily get8BitMaskFromBitmapImageRep:bitmapImageRep requiredPixelSize:32];
            break;
			
            // 'ICN#' 32x32 1-bit alpha mask
        case kLarge1BitMask:
            hRawData = [NTIconFamily get1BitMaskFromBitmapImageRep:bitmapImageRep requiredPixelSize:32];
            break;
			
            // 'icl8' 32x32 8-bit indexed image data
        case kLarge8BitData:
            hRawData = [NTIconFamily get8BitDataFromBitmapImageRep:bitmapImageRep requiredPixelSize:32];
            break;
			
            // 'is32' 16x16 32-bit RGB image
        case kSmall32BitData:
            hRawData = [NTIconFamily get32BitDataFromBitmapImageRep:bitmapImageRep requiredPixelSize:16];
            break;
			
            // 's8mk' 16x16 8-bit alpha mask
        case kSmall8BitMask:
            hRawData = [NTIconFamily get8BitMaskFromBitmapImageRep:bitmapImageRep requiredPixelSize:16];
            break;
			
            // 'ics#' 16x16 1-bit alpha mask
        case kSmall1BitMask:
            hRawData = [NTIconFamily get1BitMaskFromBitmapImageRep:bitmapImageRep requiredPixelSize:16];
            break;
			
            // 'ics8' 16x16 8-bit indexed image data
        case kSmall8BitData:
            hRawData = [NTIconFamily get8BitDataFromBitmapImageRep:bitmapImageRep requiredPixelSize:16];
            break;
			
        default:
            return NO;
    }
	
    // NSLog(@"setIconFamilyElement:%@ fromBitmapImageRep:%@ generated handle %p of size %d", NSFileTypeForHFSTypeCode(elementType), bitmapImageRep, hRawData, GetHandleSize(hRawData));
	
    if (hRawData == NULL)
    {
        NSLog(@"Null data returned to setIconFamilyElement:fromBitmapImageRep:");
        return NO;
    }
	
    result = SetIconFamilyData( [self iconFamilyHandle], elementType, hRawData );
    DisposeHandle( hRawData );
	
    if (result != noErr)
    {
        NSLog(@"SetIconFamilyData() returned error %d", result);
        return NO;
    }
	
    return YES;
}

@end

@implementation NTIconFamily (ScrapAdditions)

+ (BOOL)canInitWithPasteboard;
{
	BOOL result;
	NSPasteboard* pboard = [NSPasteboard generalPasteboard];

	NSString* type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:(NSString*)kUTTypeAppleICNS, nil]];
	result = [type length] > 0;
	
	if (!result)
		result = [NSImage canInitWithPasteboard:pboard];
		
	return result;
}

+ (NTIconFamily*)iconFamilyWithPasteboard;
{
	if ([self canInitWithPasteboard])
	{				
		NSPasteboard* pboard = [NSPasteboard generalPasteboard];
		
		NSString* type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:(NSString*)kUTTypeAppleICNS, nil]];
		if ([type length])
		{
			NSData *data = [pboard dataForType:(NSString*)kUTTypeAppleICNS];
			
			if (data)
				return [self iconFamilyWithHandle:(IconFamilyHandle)[data carbonHandle]];
		}
		else
		{
			NSImage* image = [[[NSImage alloc] initWithPasteboard:pboard] autorelease];
			
			if (image)
				return [self iconFamilyWithImage:image];
		}
	}
	
	return nil;
}

- (void)putOnPasteboard;
{		
	NSData* data = [NSData dataWithCarbonHandle:(Handle)[self iconFamilyHandle]];
	
	if (data)
	{
		NSPasteboard* pboard = [NSPasteboard generalPasteboard];
		
		[pboard declareTypes:[NSArray arrayWithObjects:(NSString*)kUTTypeAppleICNS, nil] owner:nil];
		[pboard setData:data forType:(NSString*)kUTTypeAppleICNS];
	}
}

@end

