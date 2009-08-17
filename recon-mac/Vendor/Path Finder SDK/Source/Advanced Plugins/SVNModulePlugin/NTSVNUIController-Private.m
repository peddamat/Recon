//
//  NTSVNUIController-Private.m
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 12/27/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTSVNUIController-Private.h"
#import "NTSVNUIController-html.h"
#import "NTSVNUtilities.h"
#import "NTSVNDisplayMgr.h"
#import "NTSVNAskForStringController.h"

@interface NTSVNUIController (Protocols) <NTSVNAskForStringControllerDelegate, NTSVNDisplayMgrDelegate>
@end

@interface NSString (SVNStringCategory) 
- (NSString*)stringWithEncoding:(NSStringEncoding)encoding;
@end

@implementation NTSVNUIController (Private)

- (void)runSVNTool:(NSArray*)args;
{
	[[self displayMgr] appendToToolLog:[NSString stringWithFormat:@"%@ %@", [self SVNTool], [args description]]];
	
	[[self launchedTools] addObject:[[self host] runTool:[self SVNTool]
											   directory:[[self directory] URL]
											   arguments:args 
												  target:self
												  setUID:NO]];
}

- (void)runBashTool:(NSString*)command;
{
	[[self displayMgr] appendToToolLog:command];
	
	[[self launchedTools] addObject:[[self host] runTool:[self bashTool]
											   directory:[[self directory] URL]
											   arguments:[NSArray arrayWithObjects:@"-c", command, nil] 
												  target:self
												  setUID:NO]];
}

- (void)runTool_result:(NSDictionary*)dict;
{
	NSNumber* identifier = [dict objectForKey:@"identifier"];
	
	// is this one of our tools?  We must check, it could be another plugin
	if ([[self launchedTools] containsObject:identifier])
	{
		[[self displayMgr] updateWithToolResult:dict];
		
		// remove from launched tools
		[[self launchedTools] removeObject:identifier];
	}
	else
	{
	}
}

//---------------------------------------------------------- 
//  displayMgr 
//---------------------------------------------------------- 
- (NTSVNDisplayMgr *)displayMgr
{
	if (!mDisplayMgr)
		[self setDisplayMgr:[NTSVNDisplayMgr displayMgr]];
	
    return mDisplayMgr; 
}

- (void)setDisplayMgr:(NTSVNDisplayMgr *)theDisplayMgr
{
    if (mDisplayMgr != theDisplayMgr)
    {
		[mDisplayMgr setDelegate:nil];
		
        [mDisplayMgr release];
        mDisplayMgr = [theDisplayMgr retain];
		
		[mDisplayMgr setDelegate:self];
    }
}

//---------------------------------------------------------- 
//  SVNTool 
//---------------------------------------------------------- 
- (NSString *)SVNTool
{
	if (!mSVNTool)
	{
		NSArray* paths = [NSArray arrayWithObjects:
			@"/usr/bin/svn",
			@"/usr/local/bin/svn",
			@"/opt/local/bin/svn",
			@"/sw/bin/svn",
			nil];
		NSString* path;
		
		for (path in paths)
		{
			if ([[NSFileManager defaultManager] fileExistsAtPath:path])
			{
				[self setSVNTool:path];
				break;
			}
		}
	}
	
    return mSVNTool; 
}

- (void)setSVNTool:(NSString *)theSVNTool
{
    if (mSVNTool != theSVNTool)
    {
        [mSVNTool release];
        mSVNTool = [theSVNTool retain];
    }
}

- (NSString*)bashTool;
{
	return @"/bin/bash";
}

//---------------------------------------------------------- 
//  directory 
//---------------------------------------------------------- 
- (id<NTFSItem>)directory
{
    return mDirectory; 
}

- (void)setDirectory:(id<NTFSItem>)theDirectory
{
    if (mDirectory != theDirectory)
    {
        [mDirectory release];
        mDirectory = [theDirectory retain];
    }
}

//---------------------------------------------------------- 
//  HTMLHeaderString 
//---------------------------------------------------------- 
- (NSString *)HTMLHeaderString
{
	if (!mHTMLHeaderString)
	{
		[self setHTMLHeaderString:[NSString stringWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"htmlHeader" ofType:@"txt"]
													 encoding:NSUTF8StringEncoding error:nil]];
	}
	
    return mHTMLHeaderString; 
}

- (void)setHTMLHeaderString:(NSString *)theHTMLHeaderString
{
    if (mHTMLHeaderString != theHTMLHeaderString)
    {
        [mHTMLHeaderString release];
        mHTMLHeaderString = [theHTMLHeaderString retain];
    }
}

- (NSString*)htmlWithSections:(NSArray*)headerSections body:(NSArray*)bodySections;
{	
	NSMutableString* result = [NSMutableString stringWithString:[self HTMLHeaderString]];
	
	[result appendString:@"<body>"];
	
	NSString* section;
	
	// header
	[result appendString:@"<div id=\"header\">"];
	for (section in headerSections)
		[result appendString:section];
	[result appendString:@"</div>"];

	// body
	[result appendString:@"<div id=\"output\">"];
	for (section in bodySections)
		[result appendString:section];
	[result appendString:@"</div>"];

	NSString* footer = @"</body></html>";
	[result appendString:footer];
	
	return result;
}

- (void)refreshHTML;
{
	NSString* html = [self htmlWithSections:[NSArray arrayWithObjects:[self repositoryHTML], [self navBarHTML], nil]
									   body:[NSArray arrayWithObjects:[[self displayMgr] displayString], [self footerHTML], nil]];
	
	[[[self webView] mainFrame] loadHTMLString:html baseURL:nil];
}	

- (void)saveScrollPosition;
{
	NSScrollView* scrollView = [self findScrollView:[self webView]];
	[self setDocumentVisibleRect:[scrollView documentVisibleRect]];
}

//---------------------------------------------------------- 
//  documentVisibleRect 
//---------------------------------------------------------- 
- (NSRect)documentVisibleRect
{
    return mDocumentVisibleRect;
}

- (void)setDocumentVisibleRect:(NSRect)theDocumentVisibleRect
{
    mDocumentVisibleRect = theDocumentVisibleRect;
}

- (NSScrollView*)findScrollView:(NSView*)view;
{
	NSScrollView *result = nil;
	NSEnumerator *enumerator = [[view subviews] objectEnumerator];
	id obj;
	
	while (obj = [enumerator nextObject])
	{
		if ([obj isKindOfClass:[NSScrollView class]])
			result = (NSScrollView*) obj;
		else
			result = [self findScrollView:obj];
		
		if (result)
			break;
	}
	
	return result;
}

//---------------------------------------------------------- 
//  webView 
//---------------------------------------------------------- 
- (WebView *)webView
{
	if (!mWebView)
	{
		[self setWebView:[[[WebView alloc] initWithFrame:NSZeroRect] autorelease]];
		
		// set prefs identifier
		[[self webView] setPreferencesIdentifier:NSStringFromClass([self class])];
		
		// make sure the prefs have the settings we want
		WebPreferences *prefs = [[self webView] preferences];
		[prefs setDefaultFontSize:12.0];
		[prefs setJavaScriptEnabled:YES];
		[prefs setJavaScriptCanOpenWindowsAutomatically:NO];
				
		// set scrollbars to small (doesn't work)
		NSScrollView *scrollView = [self findScrollView:[self webView]];
				
		if ([scrollView verticalScroller])
			[[scrollView verticalScroller] setControlSize:NSSmallControlSize];
		if ([scrollView horizontalScroller])
			[[scrollView horizontalScroller] setControlSize:NSSmallControlSize];
		
		[self refreshHTML];
	}
	
    return mWebView; 
}

- (void)setWebView:(WebView *)theWebView
{
    if (mWebView != theWebView)
    {
		[mWebView setFrameLoadDelegate:nil];
		[mWebView setUIDelegate:nil];
		[mWebView setPolicyDelegate:nil];
		
        [mWebView release];
        mWebView = [theWebView retain];
		
		[mWebView setFrameLoadDelegate:self];
		[mWebView setUIDelegate:self];
		[mWebView setPolicyDelegate:self];
    }
}

//---------------------------------------------------------- 
//  launchedTools 
//---------------------------------------------------------- 
- (NSMutableSet *)launchedTools
{
	if (!mLaunchedTools)
		[self setLaunchedTools:[NSMutableSet set]];
	
    return mLaunchedTools; 
}

- (void)setLaunchedTools:(NSMutableSet *)theLaunchedTools
{
    if (mLaunchedTools != theLaunchedTools)
    {
        [mLaunchedTools release];
        mLaunchedTools = [theLaunchedTools retain];
    }
}

- (void)askUserToRemove:(NSString*)path;
{
	if ([path length])
	{
		NSDictionary* context = [NSDictionary dictionaryWithObjectsAndKeys:
			self, @"target", 
			@"rm", @"command",
			path, @"path",
			nil];
		
		[[self host] askUser:@"Do you want to remove this file from svn?"
					 message:path
					okButton:@"Remove"
				cancelButton:@"Cancel"
					  window:[[self host] sheetWindow:[[self view] window]]
					 context:context];
	}
	else
		NSBeep();
}

- (void)askUserToRevert:(NSString*)path;
{
	if ([path length])
	{
		NSDictionary* context = [NSDictionary dictionaryWithObjectsAndKeys:
			self, @"target", 
			@"revert", @"command",
			path, @"path",
			nil];
		
		[[self host] askUser:@"Do you want to revert this file?"
					 message:path
					okButton:@"Revert"
				cancelButton:@"Cancel"
					  window:[[self host] sheetWindow:[[self view] window]]
					 context:context];	
	}
	else
		NSBeep();
}

// call back for [[self host] askUser
- (void)askUser_response:(BOOL)canceled context:(NSDictionary*)context;
{
	if (!canceled)
	{
		NSString* command = [context objectForKey:@"command"];
		NSString* path = [context objectForKey:@"path"];
				
		// handles rm and revert
		if ([command length] && [path length])
		{
			[[self displayMgr] updateProgress:[NSString stringWithFormat:@"svn %@", command]];
			
			[self runSVNTool:[NSArray arrayWithObjects:command, path, nil]];
		}
	}
}

- (void)askUserForCommitComments;
{
	[NTSVNAskForStringController ask:@"Enter comments" sheetWindow:[[self host] sheetWindow:[[self view] window]] delegate:self context:NSStringFromSelector(_cmd)];
}

- (void)askUserForOtherCommand;
{
	[NTSVNAskForStringController ask:@"Enter an svn command" sheetWindow:[[self host] sheetWindow:[[self view] window]] delegate:self context:NSStringFromSelector(_cmd)];
}

//---------------------------------------------------------- 
//  restoreScrollPosition 
//---------------------------------------------------------- 
- (BOOL)restoreScrollPosition
{
    return mRestoreScrollPosition;
}

- (void)setRestoreScrollPosition:(BOOL)flag
{
    mRestoreScrollPosition = flag;
}

//---------------------------------------------------------- 
//  whichSVNCommand 
//---------------------------------------------------------- 
- (NSNumber *)whichSVNCommand
{
    return mWhichSVNCommand; 
}

- (void)setWhichSVNCommand:(NSNumber *)theWhichSVNCommand
{
    if (mWhichSVNCommand != theWhichSVNCommand)
    {
        [mWhichSVNCommand release];
        mWhichSVNCommand = [theWhichSVNCommand retain];
    }
}

@end

@implementation NTSVNUIController (Protocols) 

// <NTSVNAskForStringControllerDelegate>

- (void)askForString_result:(NSString*)result canceled:(BOOL)canceled context:(id)context;
{
	if (canceled)
		return;
	
	if ([context isKindOfClass:[NSString class]])
	{
		if ([context isEqualToString:@"askUserForCommitComments"])
		{
			// umlauts and crap fuck up svn, remove here
			result = [result stringWithEncoding:NSASCIIStringEncoding];

			if ([result length] && [self directory])
			{
				[[self displayMgr] updateProgress:@"svn commit"];
								
				[self runSVNTool:[NSArray arrayWithObjects:@"commit", @"-m", result, nil]];
			}
			else 
			{
				NSBeep();
				[[self displayMgr] updateMessage:@"commit comments are required."];
			}
		}
		else if ([context isEqualToString:@"askUserForOtherCommand"])
		{
			if ([result length] && [self directory])
			{
				// strip off svn if user added it
				if ([result hasPrefix:@"svn "])
					result = [result substringFromIndex:4];
				
				result = [NSString stringWithFormat:@"%@ %@", [self SVNTool], result];
				
				[[self displayMgr] updateProgress:result];
								
				[self runBashTool:result];
			}
		}
	}
}

// NTSVNDisplayMgrDelegate 

- (void)displayMgr_refreshHTML:(NTSVNDisplayMgr*)mgr;
{
	[self refreshHTML];
}

- (void)displayMgr_restoreScrollPositionOnReload:(NTSVNDisplayMgr*)mgr;
{
	[self setRestoreScrollPosition:YES];
}

@end

@implementation NSString (SVNStringCategory) 

- (NSString*)stringWithEncoding:(NSStringEncoding)encoding;
{
	NSData* data = [self dataUsingEncoding:encoding allowLossyConversion:YES];
	
	return [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
}

@end

