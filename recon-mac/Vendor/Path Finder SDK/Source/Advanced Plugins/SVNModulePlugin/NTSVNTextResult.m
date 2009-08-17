//
//  NTSVNTextResult.m
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTSVNTextResult.h"
#import "NTSVNUtilities.h"

@interface NTSVNTextResult (Private)
- (NSString*)buildHTML;

- (NSString *)result;
- (void)setResult:(NSString *)theResult;
@end

@implementation NTSVNTextResult

// send output from task, parse and hold results
+ (NTSVNTextResult*)result:(NSString*)res;
{
	NTSVNTextResult* result = [[NTSVNTextResult alloc] init];
	
	[result setResult:res];
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	[self setHTML:nil];
	[super dealloc];
}

//---------------------------------------------------------- 
//  HTML 
//---------------------------------------------------------- 
- (NSString *)HTML
{
	if (!mHTML)
		[self setHTML:[self buildHTML]];
	
	return mHTML; 
}

- (void)setHTML:(NSString *)theHTML
{
	if (mHTML != theHTML)
	{
		[mHTML release];
		mHTML = [theHTML retain];
	}
}

@end

@implementation NTSVNTextResult (Private)

- (NSString*)buildHTML;
{
	return [NTSVNUtilities htmlStringWithPre:[self result]];
}

//---------------------------------------------------------- 
//  result 
//---------------------------------------------------------- 
- (NSString *)result
{
    return mResult; 
}

- (void)setResult:(NSString *)theResult
{
    if (mResult != theResult)
    {
        [mResult release];
        mResult = [theResult retain];
    }
}

@end

