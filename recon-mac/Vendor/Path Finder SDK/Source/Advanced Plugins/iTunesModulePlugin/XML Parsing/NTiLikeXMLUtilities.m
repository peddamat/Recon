//
//  NTiLikeXMLUtilities.m
//  iLike
//
//  Created by Steve Gehrman on 4/20/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTiLikeXMLUtilities.h"
#import "GBUtilities.h"

@implementation NTiLikeXMLUtilities

+ (NSDate*)dateFromString:(NSString*)dateString;
{
	static NSDateFormatter *shared = nil;
	
	if (!shared)
	{
		shared = [[NSDateFormatter alloc] init];
		[shared setDateStyle:kCFDateFormatterFullStyle];
	}
	
	NSDate* result = [shared dateFromString:dateString];
	
	return result;
}

+ (NSString*)convertKey:(NSString*)key;
{
	if ([key isEqualToString:@"Name"])
		return @"name";
	else if ([key isEqualToString:@"Artist"])
		return @"artist";
	else if ([key isEqualToString:@"Album"])
		return @"album";
	else if ([key isEqualToString:@"Track ID"])
		return @"id";
	else if ([key isEqualToString:@"Play Count"])
		return @"plays";
	else if ([key isEqualToString:@"Genre"])
		return @"genre";
	else if ([key isEqualToString:@"Date Modified"])
		return @"tmod";
	else if ([key isEqualToString:@"Date Added"])
		return @"tadd";
	else if ([key isEqualToString:@"Play Date UTC"])
		return @"tplay";
	else if ([key isEqualToString:@"Kind"])
		return @"format";
	else if ([key isEqualToString:@"Playlist Persistent ID"])
		return @"id";
	else if ([key isEqualToString:@"tracks"]) // no change
		return key;
	
	return nil;
}

+ (NSString*)cleanString:(NSString*)str;
{
	static NSCharacterSet* sharedCharSet = nil;
	
	if (!sharedCharSet)
		sharedCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"\r\n"] retain];
				
	str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	str = [str GB_stringByReplacingOccurrencesOfCharactersInSet:sharedCharSet toString:@""];
	
	return str;
}

+ (NSDictionary*)cleanInfoDict:(NSDictionary*)trackDict;
{
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	NSEnumerator* enumerator = [trackDict keyEnumerator];
	NSString *key, *obj;
	
	while (key = [enumerator nextObject])
	{
		obj = [trackDict objectForKey:key];
		key = [self convertKey:key];
		
		if ([obj isKindOfClass:[NSString class]])
			obj = [self cleanString:obj];
		
		if ([key isKindOfClass:[NSString class]])
			key = [self cleanString:key];
		
		if (key)
			[result setObject:obj forKey:key];
	}
	
	// append source
	[result setObject:@"iTunes" forKey:@"source"];
	
	return result;
}

@end
