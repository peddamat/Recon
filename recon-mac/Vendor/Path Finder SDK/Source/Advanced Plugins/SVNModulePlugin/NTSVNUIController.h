//
//  NTSVNUIController.h
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTPathFinderPluginHostProtocol.h"

@class NTSVNUIModel,NTSVNDisplayMgr, NTSVNTextResult, NTSVNStatusResult;

@interface NTSVNUIController : NSObject 
{
	id<NTPathFinderPluginHostProtocol> host;
	WebView* mWebView;
	
	NSRect mDocumentVisibleRect;
	BOOL mRestoreScrollPosition;
	
	id<NTFSItem> mDirectory;
	
	NSMutableSet * mLaunchedTools; // NSNumber: the ID of the plugins launched by us
	NSNumber* mWhichSVNCommand;
	NSString* mSVNTool; // result from whichSVNCommand
	
	NTSVNDisplayMgr* mDisplayMgr;
	NSString* mHTMLHeaderString;  // read from htmlHeader.txt, cached for speed
}

@property (retain) id<NTPathFinderPluginHostProtocol> host;

+ (NTSVNUIController*)controller:(id<NTPathFinderPluginHostProtocol>)theHost;

- (NSView *)view;
- (void)updateDirectory;

@end
