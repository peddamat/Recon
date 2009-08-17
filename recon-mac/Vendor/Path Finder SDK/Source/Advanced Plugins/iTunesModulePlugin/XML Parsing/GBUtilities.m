//
//  GBUtilities.m
//  iLike
//
//  Created by Steve Gehrman on 9/28/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "GBUtilities.h"

@implementation GBUtilities

+ (BOOL)extensionIsMusic:(NSString*)ext;
{
	static NSArray *shared = nil;
	
	if (!shared)
	{
		shared = [[NSArray arrayWithObjects:
			@"mp3",
			@"m4a",
			@"aac",
			@"aif",
			@"aiff",
			@"m4p",
			@"wav",
			nil] retain];
	}
	
	return [shared containsObject:[ext lowercaseString]];
}
	
+ (NSView*)findView:(NSView*)view ofClass:(Class)class;
{
	NSEnumerator *enumerator = [[view subviews] objectEnumerator];
	NSView* result=nil;
	
	while (!result && (view = [enumerator nextObject]))
	{
		if ([view isKindOfClass:class])
			result = view;
		else
			result = [self findView:view ofClass:class];
	}
	
	return result;
}

@end

@implementation NSString (GBAdditions)

- (NSString*)GB_stringByReplacing:(NSString *)value with:(NSString *)newValue;
{
    NSMutableString *newString = [NSMutableString stringWithString:self];
	
    [newString replaceOccurrencesOfString:value withString:newValue options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
	
    return newString;
}

- (NSString *)GB_stringByRemovingPrefix:(NSString *)prefix;
{
    NSRange aRange;
	
    aRange = [self rangeOfString:prefix options:NSAnchoredSearch];
    if ((aRange.length == 0) || (aRange.location != 0))
        return [[self retain] autorelease];
	
    return [self substringFromIndex:aRange.location + aRange.length];
}

- (NSString *)GB_stringByRemovingSuffix:(NSString *)suffix;
{
    if (![self hasSuffix:suffix])
        return [[self retain] autorelease];
	
    return [self substringToIndex:[self length] - [suffix length]];
}

// This is similar to the above, but replaces contiguous sequences of characters from the pattern set with a single occurrence of the replacement string
- (NSString*)GB_stringByReplacingOccurrencesOfCharactersInSet:(NSCharacterSet *)set toString:(NSString *)replaceString;
{
	NSMutableString *result = nil;
	NSRange lastRange = NSMakeRange(NSNotFound, 0);
	NSRange range;
	
	for (;;)
	{
		if (result)
			range = [result rangeOfCharacterFromSet:set options:NSLiteralSearch range:NSMakeRange(0, [result length])];
		else
			range = [self rangeOfCharacterFromSet:set options:NSLiteralSearch range:NSMakeRange(0, [self length])];
		
		if (range.location == NSNotFound)
			break;
		else
		{
			if (!result)
				result = [NSMutableString stringWithString:self];
			
			// if ranges equal, that means we have two consectutive characters, just remove
			if (NSEqualRanges(range, lastRange))
				[result replaceCharactersInRange:range withString:@""]; // remove
			else
			{
				[result replaceCharactersInRange:range withString:replaceString];
			
				// add the length of the replaceString
				lastRange = range;
				lastRange.location += [replaceString length];
			}
		}
	}
	
	if (result)
		return result;
	
	return self;
}

- (NSString*)GB_canonicalString;
{
	// remove umlauts etc
	NSMutableString *noDiacritics = [[[self decomposedStringWithCanonicalMapping] mutableCopy] autorelease];
	NSCharacterSet *nonBaseSet = [NSCharacterSet nonBaseCharacterSet];
	NSRange range = NSMakeRange([noDiacritics length], 0);
	
	while (range.location > 0)
	{
		range = [noDiacritics rangeOfCharacterFromSet:nonBaseSet options:NSBackwardsSearch range:NSMakeRange(0, range.location)];
		if (range.length == 0)
			break;
		[noDiacritics deleteCharactersInRange:range];
	}
		
	NSString* result = [noDiacritics lowercaseString];
	
	// convert & to and
	result = [result GB_stringByReplacing:@"&" with:@" and "];

	// convert punctuation to spaces
	result = [result GB_stringByReplacingOccurrencesOfCharactersInSet:[NSCharacterSet punctuationCharacterSet] toString:@" "];
	
	// trim whitespace from ends
	result = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	// Remove leading a/the
	result = [result GB_stringByRemovingPrefix:@"the "];
	result = [result GB_stringByRemovingPrefix:@"a "];
	
	// Remove trailing a/the
	result = [result GB_stringByRemovingSuffix:@" the"];
	result = [result GB_stringByRemovingSuffix:@" a"];
	
	// remove all spaces
	result = [result GB_stringByReplacing:@" " with:@""];
		
    return result;
}

@end

