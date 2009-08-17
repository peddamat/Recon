//
//  NTSVNUIController.m
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTSVNUIController.h"
#import "NTSVNUIController-Private.h"
#import "NTSVNUtilities.h"
#import "NTSVNDisplayMgr.h"

@interface NTSVNUIController (hidden)
@end

@implementation NTSVNUIController

@synthesize host;

+ (NTSVNUIController*)controller:(id<NTPathFinderPluginHostProtocol>)theHost;
{
	NTSVNUIController* result = [[NTSVNUIController alloc] init];

	[result setHost:theHost];
		
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[self setWebView:nil];
	[self setHost:nil];
    [self setDirectory:nil];
	[self setDisplayMgr:nil];
    [self setLaunchedTools:nil];
	[self setSVNTool:nil];
	[self setHTMLHeaderString:nil];

    [super dealloc];
}

- (void)updateDirectory;
{
	NSString* syncToBrowserID = [[self host] syncToBrowserID];
	id<NTFSItem> newDir = [[self host] currentDirectory:[[self webView] window] browserID:syncToBrowserID];
	
	if (![self directory] || ![[[self directory] path] isEqualToString:[newDir path]])
	{
		[self setDirectory:newDir];
		
		[[self displayMgr] invalidate];
	}
}

//---------------------------------------------------------- 
//  view 
//---------------------------------------------------------- 
- (NSView *)view
{
    return [self webView]; 
}

@end

@implementation NTSVNUIController (WebViewDelegate)

// -------------------------------------------------------------
// WebFrameLoadDelegate

- (void)webView:(WebView *)sender windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject
{	
}

- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message
{
    NSLog(@"Alert: %@", message);
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;
{
	NSScrollView* scrollView = [self findScrollView:sender];
	
	if ([self restoreScrollPosition])
	{
		if (!NSIsEmptyRect([self documentVisibleRect]))
		{
			[[scrollView documentView] scrollRectToVisible:[self documentVisibleRect]];
			[self setDocumentVisibleRect:NSZeroRect];
		}
		
		[self setRestoreScrollPosition:NO];
	}
	
	// dump html for debugging
	//	if (frame == [sender mainFrame])
	//	 	NSLog(@"start\n %@ \nend", [(DOMHTMLElement *)[[[sender mainFrame] DOMDocument] documentElement] outerHTML]);
}

// -------------------------------------------------------------
// WebPolicyDelegate

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation
		request:(NSURLRequest *)request
		  frame:(WebFrame *)frame
decisionListener:(id<WebPolicyDecisionListener>)listener;
{	
	BOOL handled=NO;
	
	if ([self directory])
	{
		NSURL *url = [request URL];		
		if ([[url scheme] isEqualToString:@"mshp"])
		{
			NSString *command = [url host];

			NSString *path = [url path];
			if ([path length])
			{
				path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				
				if ([path hasPrefix:@"/"])
					path = [path substringFromIndex:1];
			}				
			
			if ([command isEqualToString:@"status"])
			{
				[[self displayMgr] updateProgress:@"svn status"];
				
				[self runSVNTool:[NSArray arrayWithObjects:@"status", @"--xml", nil]];
			}
			else if ([command isEqualToString:@"terminal"])
			{
				[[self host] openTerminal:[self directory]];
			}
			else if ([command isEqualToString:@"update"])
			{
				[[self displayMgr] updateProgress:@"svn update"];
								
				[self runSVNTool:[NSArray arrayWithObjects:@"update", nil]];
			}
			else if ([command isEqualToString:@"commit"])
			{
				// ask user for commit message
				[self askUserForCommitComments];
			}
			else if ([command isEqualToString:@"diff"])
			{
				[[self displayMgr] updateProgress:@"svn diff"];

				NSArray* args;
				
				// did the diff specify a path?
				args = [NSArray arrayWithObjects:@"diff", @"-x", @"-w", nil];  // ignore whitespace option
				
				if ([path length])
					args = [args arrayByAddingObject:path];
				
				[self runSVNTool:args];
			}
			else if ([command isEqualToString:@"rm"])
			{
				[self saveScrollPosition];

				[self askUserToRemove:path];
			}
			else if ([command isEqualToString:@"revert"])
			{
				[self saveScrollPosition];

				[self askUserToRevert:path];
			}
			else if ([command isEqualToString:@"add"])
			{
				if ([path length])
				{
					[self saveScrollPosition];

					[[self displayMgr] updateProgress:@"svn add"];
					
					[self runSVNTool:[NSArray arrayWithObjects:@"add", path, nil]];
				}
				else
					NSBeep();
			}
			else if ([command isEqualToString:@"other"])
				[self askUserForOtherCommand];
			else if ([command isEqualToString:@"raw"])
				[[self displayMgr] showToolLog];
			else
				NSBeep();
			
			handled = YES;
		}
	}
	
	if (handled)
		[listener ignore];
	else
		[listener use];
}

- (void)webView:(WebView *)webView decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
		request:(NSURLRequest *)request
   newFrameName:(NSString *)frameName
decisionListener:(id<WebPolicyDecisionListener>)listener;
{	
	NSBeep();
	[listener ignore];
}

// ---------------------------------------
// WebUIDelegate

- (NSUInteger)webView:(WebView *)webView dragDestinationActionMaskForDraggingInfo:(id <NSDraggingInfo>)draggingInfo;
{
	return WebDragDestinationActionNone;
}

@end

