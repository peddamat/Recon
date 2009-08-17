//
//  NTCGImage.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/21/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTCGImage.h"
#import "NTFileTypeIdentifier.h"
#import "NTFileDesc.h"
#import "NTThumbnail.h"

@interface NTCGImage (Private)
+ (NSDictionary*)updateProperties:(NSDictionary*)dict convertObjectsToStrings:(BOOL)convertObjectsToStrings;
@end

@implementation NTCGImage

// array of dictionaries
+ (NSArray*)imageInformation:(NTFileDesc*)imageFile convertObjectsToStrings:(BOOL)convertObjectsToStrings;
{	
	NSMutableArray* result = nil;
	
	if ([[imageFile typeIdentifier] isImage])
	{
		CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef) [imageFile URL], (CFDictionaryRef)nil);
		
		if (imageSource) 
		{
			int i, cnt = CGImageSourceGetCount(imageSource);
			if (cnt)
			{
				for (i=0;i<cnt;i++)
				{
					NSDictionary* properties = [(NSDictionary*) CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) autorelease];
					
					if (properties)
					{
						properties = [self updateProperties:properties convertObjectsToStrings:convertObjectsToStrings];
						
						if (!result)
							result = [NSMutableArray array];
						
						[result addObject:properties];
					}
				}
			}
			
			CFRelease(imageSource);
		}
	}
	
	return result;
}

+ (NSString*)imageSizeString:(NTFileDesc*)imageFile;
{
	NSString* result = nil;

	NSSize size = [self imageSize:imageFile];
	if (!NSEqualSizes(NSZeroSize, size))
		result = [[NTSizeFormatter sharedInstance] sizeString:size];
	
	return result;
}

+ (NSSize)imageSize:(NTFileDesc*)imageFile;
{	
	NSSize result = NSZeroSize;
	
	if ([[imageFile typeIdentifier] isImage])
	{
		CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef) [imageFile URL], (CFDictionaryRef)nil);
		
		if (imageSource) 
		{
			int cnt = CGImageSourceGetCount(imageSource);
			if (cnt)
			{
				NSDictionary* properties = [(NSDictionary*) CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) autorelease];
				
				if (properties)
				{
					NSNumber* h = [properties objectForKey:@"PixelHeight"];
					NSNumber* w = [properties objectForKey:@"PixelWidth"];

					if (h && w)
					{
						float height = [h floatValue];
						float width = [w floatValue];
					
						result = NSMakeSize(width, height);
					}
				}
			}
			
			CFRelease(imageSource);
		}
	}
	
	return result;
}
	
@end

@implementation NTCGImage (Private)

+ (NSDictionary*)updateProperties:(NSDictionary*)dict convertObjectsToStrings:(BOOL)convertObjectsToStrings;
{
	NSMutableDictionary* result = [NSMutableDictionary dictionaryWithDictionary:dict];
	NSEnumerator *keyEnumerator = [dict keyEnumerator];
	NSString *key;
	id obj;
	
	while (key = [keyEnumerator nextObject])
	{
		obj = [result objectForKey:key];
		
		if (obj)
		{
			if ([obj isKindOfClass:[NSDictionary class]])
			{				
				obj = [self updateProperties:obj convertObjectsToStrings:convertObjectsToStrings];

				if (convertObjectsToStrings)
					obj = [obj formattedDescription];
				
				[result setObject:obj forKey:key];
			}
			else
			{
				if ([key isEqualToString:@"DateTimeDigitized"] || [key isEqualToString:@"DateTimeOriginal"] || [key isEqualToString:@"DateTime"])
				{
					// see if we can convert the date string to a more readable form
					NSCalendarDate* date = [NSCalendarDate dateWithString:obj calendarFormat:@"%Y:%m:%d %H:%M:%S"];
					if (date)
						obj = [date dateString:kMediumDate relative:YES];
					
					[result setObject:obj forKey:key];
				}
				else if ([key isEqualToString:@"Orientation"])
				{
					int index = [obj intValue];
					
					switch (index)
					{
						case 0: obj = @"Undefined"; break;
						case 1: obj = @"Normal"; break;
						case 2: obj = @"Flipped horizontal"; break;
						case 3: obj = @"Rotated 180"; break;
						case 4: obj = @"Flipped vertical"; break;
						case 5: obj = @"Transpose"; break;
						case 6: obj = @"Rotated 90"; break;
						case 7: obj = @"Transversed"; break;
						case 8: obj = @"Rotated 270"; break;
						default: break;
					}
					
					[result setObject:obj forKey:key];
				}
				else if ([key isEqualToString:@"FocalLength"])
					[result setObject:[NSString stringWithFormat:@"%4.1fmm", (double)[obj doubleValue]] forKey:key];
				else if ([key isEqualToString:@"FocalLenIn35mmFilm"])
					[result setObject:[NSString stringWithFormat:@"%dmm", [obj intValue]] forKey:key];
				else if ([key isEqualToString:@"LightSource"])
				{
					int lightSource = [obj intValue];
					switch (lightSource)
					{
						case 1: obj = @"Daylight"; break;
						case 2: obj = @"Fluorescent"; break;
						case 3: obj = @"Incandescent"; break;
						case 4: obj = @"Flash"; break;
						case 9: obj = @"Fine weather"; break;
						case 11: obj = @"Shade"; break;
						default:
							obj = [NSString stringWithFormat:@"Unknown(%d)", lightSource];
							break; 
					}
					[result setObject:obj forKey:key];
				}
				else if ([key isEqualToString:@"ExposureTime"])
				{
					float exposure = [obj floatValue];
					if (exposure < 0.010)
						obj = [NSString stringWithFormat:@"%6.4f s ", (double)exposure];
					else
						obj = [NSString stringWithFormat:@"%5.3f s ", (double)exposure];
					
					if (exposure <= 0.5)
						obj = [obj stringByAppendingString:[NSString stringWithFormat:@" (1/%d)",(int)(0.5 + 1/exposure)]];
					
					[result setObject:obj forKey:key];
				}
				else if ([key isEqualToString:@"FNumber"])
				{
					obj = [NSString stringWithFormat:@"f/%3.1f",(double)[obj doubleValue]];
					
					[result setObject:obj forKey:key];
				}
				else if ([key isEqualToString:@"MeteringMode"])
				{
					int mode = [obj intValue];
					switch (mode)
					{
						case 2: obj = @"Center weight"; break;
						case 3: obj = @"Spot"; break;
						case 5: obj = @"Matrix"; break;
						default: break;
					}
					
					[result setObject:obj forKey:key];
				}
				else if ([key isEqualToString:@"ExifVersion"] || [key isEqualToString:@"FlashPixVersion"])
				{ 
					// remove keys
					[result removeObjectForKey:key];
				}
				else
				{
					if (convertObjectsToStrings)
						obj = [obj formattedDescription];
					
					[result setObject:obj forKey:key];
				}
			}
		}
	}
	
	return result;
}

@end

// use someday

#if 0



if (imageInfoPtr->IsColor == 0)
[result setObject:@"Black and white" forKey:@"Color"];

if (imageInfoPtr->FlashUsed >= 0)
[result setObject:imageInfoPtr->FlashUsed ? @"Yes" :@"No" forKey:@"Flash used"];


if (imageInfoPtr->Distance)
{
	if (imageInfoPtr->Distance < 0)
		[result setObject:@"Infinite" forKey:@"Focus"];
	else
		[result setObject:[NSString stringWithFormat:@"%4.2fm",(double)imageInfoPtr->Distance] forKey:@"Focus"];
}

if (imageInfoPtr->ISOequivalent)
[result setObject:[NSString stringWithFormat:@"%2d",(int)imageInfoPtr->ISOequivalent] forKey:@"ISO equiv."];

if (imageInfoPtr->ExposureBias)
[result setObject:[NSString stringWithFormat:@"%4.2f",(double)imageInfoPtr->ExposureBias] forKey:@"Exposure bias"];

if (imageInfoPtr->Whitebalance)
{
	switch(imageInfoPtr->Whitebalance) 
	{
		case 1:
			[result setObject:@"Manual" forKey:@"White balance"];
			break;
		case 0:
			[result setObject:@"Auto" forKey:@"White balance"];
			break;
		default:
			[result setObject:@"Auto" forKey:@"White balance"];
			break;
	}
}

if (imageInfoPtr->ExposureProgram)
{
	switch(imageInfoPtr->ExposureProgram) 
	{
		case 2:
			[result setObject:@"Auto" forKey:@"Exposure program"];
			break;
		case 3:
			[result setObject:@"Aperture priority" forKey:@"Exposure program"];
			break;
		case 4:
			[result setObject:@"Shutter priority" forKey:@"Exposure program"];
			break;
			
		case 1:
			// The Kodak DX6340 (and may be others) use ExposureProgram number 1 for
			// Shutter Priority program with times shorter than 0.5 seconds
			[result setObject:@"Shutter priority" forKey:@"Exposure program"];
			break;
			
			// Some other programs from DX6340
		case 7:
			[result setObject:@"Portrait" forKey:@"Exposure program"];
			break;
		case 6:
			[result setObject:@"Action" forKey:@"Exposure program"];
			break;
		default:
			[result setObject:@"Auto" forKey:@"Exposure program"];
	}
}

{
	int a;
	for (a=0;;a++)
	{
		if (ProcessTable[a].Tag == imageInfoPtr->Process || ProcessTable[a].Tag == 0)
		{
			[result setObject:[NSString stringWithMacOSRomanString:ProcessTable[a].Desc] forKey:@"JPEG process"];
			break;
		}
	}
}

if (imageInfoPtr->Comments[0])
{
	NSString* comment = [NSString stringWithMacOSRomanString:(const char*)imageInfoPtr->Comments];
	
	comment = [comment stringByReplacing:@"\n" with:@" "];
	
	if ([comment length])
		[result setObject:comment forKey:@"Comment"];
}

#endif
