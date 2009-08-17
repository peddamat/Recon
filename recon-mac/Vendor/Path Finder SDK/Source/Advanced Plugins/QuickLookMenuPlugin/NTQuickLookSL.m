//
//  NTQuickLookSL.m
//  QuickLookMenuPlugin
//
//  Created by Steve Gehrman on 12/17/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import "NTQuickLookSL.h"

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5

@implementation NTQuickLookSL

@synthesize useZoomEffectsOnClose;

+ (NTQuickLookSL*)sharedInstance;
{
	static id shared=nil;
	
	if (!shared)
		shared = [[NTQuickLookSL alloc] init];
	
	return shared;
}

- (void)showURLs:(NSArray*)urls 
	  zoomEffect:(BOOL)zoomEffect
	  fullScreen:(BOOL)fullScreen;
{	
	if (![self isOpen])
	{		
		if (fullScreen)
			[[QLPreviewPanel sharedPreviewPanel] enterFullScreenMode:nil withOptions:nil];
		else
			[[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
	}
}

- (BOOL)isOpen;
{
	return [[QLPreviewPanel sharedPreviewPanel] isVisible];
}

- (void)close;
{
	[[QLPreviewPanel sharedPreviewPanel] close];
}

- (void)setDelegate:(id)delegate;
{
}

- (NSRect)windowFrame;
{
	return [[QLPreviewPanel sharedPreviewPanel] frame];
}

@end

#endif

