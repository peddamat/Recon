//
//  NTSVNUIController-Private.h
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 12/27/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTSVNUIController.h"

@interface NTSVNUIController (Private)
- (NTSVNDisplayMgr *)displayMgr;
- (void)setDisplayMgr:(NTSVNDisplayMgr *)theDisplayMgr;

- (void)askUserForCommitComments;
- (void)askUserForOtherCommand;
- (void)askUserToRemove:(NSString*)path;
- (void)askUserToRevert:(NSString*)path;

- (void)runSVNTool:(NSArray*)args;
- (void)runBashTool:(NSString*)command;

- (NSMutableSet *)launchedTools;
- (void)setLaunchedTools:(NSMutableSet *)theLaunchedTools;

- (NSString *)HTMLHeaderString;
- (void)setHTMLHeaderString:(NSString *)theHTMLHeaderString;

- (NSString *)SVNTool;
- (void)setSVNTool:(NSString *)theSVNTool;

- (NSString*)bashTool;

- (id<NTFSItem>)directory;
- (void)setDirectory:(id<NTFSItem>)theDirectory;

- (WebView *)webView;
- (void)setWebView:(WebView *)theWebView;

- (NSScrollView*)findScrollView:(NSView*)view;

// for saving scroll position
- (void)saveScrollPosition;
- (NSRect)documentVisibleRect;
- (void)setDocumentVisibleRect:(NSRect)theDocumentVisibleRect;
- (BOOL)restoreScrollPosition;
- (void)setRestoreScrollPosition:(BOOL)flag;

- (void)refreshHTML;
@end
