//
//  NTSVNDisplayMgr.m
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 1/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTSVNDisplayMgr.h"
#import "NTSVNStatusResult.h"
#import "NTSVNTextResult.h"
#import "NTSVNUtilities.h"

@interface NTSVNDisplayMgr (Private)
- (NTSVNDisplayMode)mode;
- (void)setMode:(NTSVNDisplayMode)theMode;

- (NTSVNStatusResult *)statusResult;
- (void)setStatusResult:(NTSVNStatusResult *)theStatusResult;

- (NTSVNTextResult *)textResult;
- (void)setTextResult:(NTSVNTextResult *)theTextResult;

- (NSURL *)progressBarURL;
- (void)setProgressBarURL:(NSURL *)theProgressBarURL;

- (NSString *)progressHTML;
- (void)setProgressHTML:(NSString *)theProgressHTML;

- (NSString *)errorHTML;
- (void)setErrorHTML:(NSString *)theErrorHTML;

- (NSString *)toolLogHTML;
- (void)setToolLogHTML:(NSString *)theToolLogHTML;

- (NSMutableString *)toolLog;
- (void)setToolLog:(NSMutableString *)theToolLog;

- (NSString *)delayedProgressString;
- (void)setDelayedProgressString:(NSString *)theDelayedProgressString;
@end

#define kDelayedProgressSEL @selector(delayedProgress)

@implementation NTSVNDisplayMgr

+ (NTSVNDisplayMgr*)displayMgr;
{
	NTSVNDisplayMgr* result = [[NTSVNDisplayMgr alloc] init];
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	if ([self delegate])
		NSLog(@"-[%@ %@] need to clear delegate", [self className], NSStringFromSelector(_cmd));

    [self setStatusResult:nil];
    [self setTextResult:nil];
    [self setProgressHTML:nil];
    [self setErrorHTML:nil];
    [self setToolLogHTML:nil];
    [self setToolLog:nil];
	[self setDelayedProgressString:nil];

    [super dealloc];
}

- (NSString*)displayString;
{
	switch ([self mode])
	{
		case kSVNDisplayMode_status:
			if ([self statusResult])
				return [[self statusResult] HTML];
			break;
		case kSVNDisplayMode_text:
			if ([self textResult])
				return [[self textResult] HTML];
			break;
		case kSVNDisplayMode_error:
			if ([self errorHTML])
				return [self errorHTML];
			break;
		case kSVNDisplayMode_toolLog:
			if ([self toolLogHTML])
				return [self toolLogHTML];
			break;
		case kSVNDisplayMode_progress:
			if ([self progressHTML])
				return [self progressHTML];
			break;
			
		case kSVNDisplayMode_none:
		default:
			break;
	}
	
	return @"";
}

//---------------------------------------------------------- 
//  delegate 
//---------------------------------------------------------- 
- (id<NTSVNDisplayMgrDelegate>)delegate
{
    return mDelegate; 
}

- (void)setDelegate:(id<NTSVNDisplayMgrDelegate>)theDelegate
{
    if (mDelegate != theDelegate)
        mDelegate = theDelegate;
}

- (void)updateProgress:(NSString*)progress;
{
	[self setDelayedProgressString:progress];
	[self performSelector:kDelayedProgressSEL withObject:nil afterDelay:.5];
}

- (void)delayedProgress;
{
	NSURL *imageURL = [self progressBarURL];
	
	[self setProgressHTML:[NSString stringWithFormat:
		@"<p align="
		"\"center\">%@<br><br>"
		"<img src=\"%@\"></img></p>", 
		[self delayedProgressString], [imageURL absoluteString]]];
	
	[self setMode:kSVNDisplayMode_progress];
}

- (void)invalidate;
{
	[self setErrorHTML:nil];
	[self setStatusResult:nil];
	[self setTextResult:nil];
	[self setProgressHTML:nil];

	[self setMode:kSVNDisplayMode_none];
}	

- (void)appendToToolLog:(NSString*)append;
{
	[[self toolLog] appendString:[NSString stringWithFormat:@"%@: %@\n", [[NSDate date] description], append]];
	
	[self setToolLogHTML:nil]; // must clear this out, no longer valid
}

- (void)showToolLog;
{
	[self setMode:kSVNDisplayMode_toolLog];
}

- (void)updateWithToolResult:(NSDictionary*)dict;
{
	NSArray* arguments = [dict objectForKey:@"arguments"];
	NSString* result = [dict objectForKey:@"result"];
	NSString* error = [dict objectForKey:@"error"];
	
	if ([error length])
		[self appendToToolLog:[NSString stringWithFormat:@"Error:%@",error]];
	else if ([result length])
		[self appendToToolLog:result];
	
	// clear previous results and errors
	[self setMode:kSVNDisplayMode_none];
	
	if ([error length])
	{
		[self setErrorHTML:[NTSVNUtilities htmlStringWithPre:[NSString stringWithFormat:@"Error: %@", error]]];
		
		[self setMode:kSVNDisplayMode_error];
	}
	else if ([result length])
	{
		NSString* command = [arguments objectAtIndex:0];
		
		// is this a result from a status command?
		if ([command isEqualToString:@"status"])
		{
			[self setStatusResult:[NTSVNStatusResult result:result]];
			
			[self setMode:kSVNDisplayMode_status];
		}
		else
		{
			BOOL setTextResult = YES;
			
			// mode is progress at this point
			if ([self statusResult])
			{
				if ([command isEqualToString:@"add"] ||
					[command isEqualToString:@"rm"] ||
					[command isEqualToString:@"revert"])
				{
					NSString* path = [arguments objectAtIndex:1];

					// update our status for the add
					if ([[self statusResult] updateForCommand:command path:path])
					{
						setTextResult = NO;
						
						// show the status again
						[[self delegate] displayMgr_restoreScrollPositionOnReload:self]; // attempt to restore scroll position on this reload
						[self setMode:kSVNDisplayMode_status];
					}
				}
			}
				
			if (setTextResult)
				[self updateMessage:result];
		}
	}
}

- (void)updateMessage:(NSString*)message;
{
	[self setTextResult:[NTSVNTextResult result:message]];
	[self setMode:kSVNDisplayMode_text];
}
 
@end

@implementation NTSVNDisplayMgr (Private)

//---------------------------------------------------------- 
//  mode 
//---------------------------------------------------------- 
- (NTSVNDisplayMode)mode
{
    return mMode;
}

- (void)setMode:(NTSVNDisplayMode)theMode
{
	// cancel any delayed progress messages
	[self retain];  // for safety, cancelPreviousPerformRequestsWithTarget can release us if this was the last thing retaining self
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:kDelayedProgressSEL object:nil];
	[self autorelease]; 
	
    mMode = theMode;
	
	// refresh html if mode changes
	[[self delegate] displayMgr_refreshHTML:self];
}

//---------------------------------------------------------- 
//  statusResult 
//---------------------------------------------------------- 
- (NTSVNStatusResult *)statusResult
{
    return mStatusResult; 
}

- (void)setStatusResult:(NTSVNStatusResult *)theStatusResult
{
    if (mStatusResult != theStatusResult)
    {
        [mStatusResult release];
        mStatusResult = [theStatusResult retain];
    }
}

//---------------------------------------------------------- 
//  textResult 
//---------------------------------------------------------- 
- (NTSVNTextResult *)textResult
{
    return mTextResult; 
}

- (void)setTextResult:(NTSVNTextResult *)theTextResult
{
    if (mTextResult != theTextResult)
    {
        [mTextResult release];
        mTextResult = [theTextResult retain];
    }
}

//---------------------------------------------------------- 
//  progressBarURL 
//---------------------------------------------------------- 
- (NSURL *)progressBarURL
{
	if (!mProgressBarURL)
		[self setProgressBarURL:[NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"progressBar"]]];
	
    return mProgressBarURL; 
}

- (void)setProgressBarURL:(NSURL *)theProgressBarURL
{
    if (mProgressBarURL != theProgressBarURL)
    {
        [mProgressBarURL release];
        mProgressBarURL = [theProgressBarURL retain];
    }
}

//---------------------------------------------------------- 
//  progressHTML 
//---------------------------------------------------------- 
- (NSString *)progressHTML
{
    return mProgressHTML; 
}

- (void)setProgressHTML:(NSString *)theProgressHTML
{
    if (mProgressHTML != theProgressHTML)
    {
        [mProgressHTML release];
        mProgressHTML = [theProgressHTML retain];
    }
}

//---------------------------------------------------------- 
//  errorHTML 
//---------------------------------------------------------- 
- (NSString *)errorHTML
{
    return mErrorHTML; 
}

- (void)setErrorHTML:(NSString *)theErrorHTML
{
    if (mErrorHTML != theErrorHTML)
    {
        [mErrorHTML release];
        mErrorHTML = [theErrorHTML retain];
    }
}

//---------------------------------------------------------- 
//  toolLogHTML 
//---------------------------------------------------------- 
- (NSString *)toolLogHTML
{
	if (!mToolLogHTML)
		[self setToolLogHTML:[NTSVNUtilities htmlStringWithPre:[self toolLog]]];

    return mToolLogHTML; 
}

- (void)setToolLogHTML:(NSString *)theToolLogHTML
{
    if (mToolLogHTML != theToolLogHTML)
    {
        [mToolLogHTML release];
        mToolLogHTML = [theToolLogHTML retain];
    }
}

//---------------------------------------------------------- 
//  toolLog 
//---------------------------------------------------------- 
- (NSMutableString *)toolLog
{
	if (!mToolLog)
		[self setToolLog:[NSMutableString string]];

    return mToolLog; 
}

- (void)setToolLog:(NSMutableString *)theToolLog
{
    if (mToolLog != theToolLog)
    {
        [mToolLog release];
        mToolLog = [theToolLog retain];
    }
}

//---------------------------------------------------------- 
//  delayedProgressString 
//---------------------------------------------------------- 
- (NSString *)delayedProgressString
{
    return mDelayedProgressString; 
}

- (void)setDelayedProgressString:(NSString *)theDelayedProgressString
{
    if (mDelayedProgressString != theDelayedProgressString)
    {
        [mDelayedProgressString release];
        mDelayedProgressString = [theDelayedProgressString retain];
    }
}

@end
