//
//  NTSVNUtilities.m
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTSVNUtilities.h"

@implementation NTSVNUtilities

+ (NSString *)htmlString:(NSString*)inString;
{
    unichar *ptr, *begin, *end;
	NSMutableString *result;
	NSString *string;
	int length;
	
#define APPEND_PREVIOUS() \
	{ \
		string = [[NSString alloc] initWithCharacters:begin length:(ptr - begin)]; \
			[result appendString:string]; \
				[string release]; \
					begin = ptr + 1; \
	}
	
	length = [inString length];
	ptr = alloca(length * sizeof(unichar));
	end = ptr + length;
	[inString getCharacters:ptr];
	result = [NSMutableString stringWithCapacity:length];
	
	begin = ptr;
	while (ptr < end) {
		if (*ptr > 127) {
			APPEND_PREVIOUS();
			[result appendFormat:@"&#%d;", (int)*ptr];
		} else if (*ptr == '&') {
			APPEND_PREVIOUS();
			[result appendString:@"&amp;"];
		} else if (*ptr == '\"') {
			APPEND_PREVIOUS();
			[result appendString:@"&quot;"];
		} else if (*ptr == '<') {
			APPEND_PREVIOUS();
			[result appendString:@"&lt;"];
		} else if (*ptr == '>') {
			APPEND_PREVIOUS();
			[result appendString:@"&gt;"];
		} else if (*ptr == '\n') {
			APPEND_PREVIOUS();
			[result appendString:@"<br/>"];
		}
		ptr++;
	}
	APPEND_PREVIOUS();
	return result;
}

+ (NSString *)htmlStringWithPre:(NSString*)inString;
{
	return [NSString stringWithFormat:@"<p align=\"left\"><pre>"
		"%@"
		"</pre></p>", [NTSVNUtilities htmlString:inString]];
}

@end
