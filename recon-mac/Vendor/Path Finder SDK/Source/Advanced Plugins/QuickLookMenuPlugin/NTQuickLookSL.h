//
//  NTQuickLookSL.h
//  QuickLookMenuPlugin
//
//  Created by Steve Gehrman on 12/17/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5

@interface NTQuickLookSL : NSObject {
	BOOL useZoomEffectsOnClose; 
}

@property (assign) BOOL useZoomEffectsOnClose;

+ (NTQuickLookSL*)sharedInstance;

- (void)setDelegate:(id)delegate;

- (BOOL)isOpen;
- (NSRect)windowFrame;

- (void)showURLs:(NSArray*)urls 
	  zoomEffect:(BOOL)zoomEffect
	  fullScreen:(BOOL)fullScreen;

- (void)close;

@end

#endif