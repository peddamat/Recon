//
//  NTQuickLook.h
//  NTQuickLookMenuPlugin
//
//  Created by Steve Gehrman on 11/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5

@interface NTQuickLook : NSObject {
	BOOL mUseZoomEffectsOnClose; 
}

+ (NTQuickLook*)sharedInstance;

- (void)setDelegate:(id)delegate;

- (BOOL)isOpen;
- (NSRect)windowFrame;

- (void)showURLs:(NSArray*)urls 
	  zoomEffect:(BOOL)zoomEffect
	  fullScreen:(BOOL)fullScreen;

- (void)close;

@end

#endif

