//
//  NTQuickLook.m
//  NTQuickLookMenuPlugin
//
//  Created by Steve Gehrman on 11/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTQuickLook.h"
#import "QuicklookPrivateHeader.h"

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5

@interface QLPreviewPanelHack : QLPreviewPanel
{
}
+ (void)install;
@end

@interface NTQuickLook (Private)
- (BOOL)useZoomEffectsOnClose;
- (void)setUseZoomEffectsOnClose:(BOOL)flag;
@end

@implementation NTQuickLook

+ (void)initialize;
{
	[QLPreviewPanelHack install];
}

+ (NTQuickLook*)sharedInstance;
{
	static id shared=nil;
	
	if (!shared)
		shared = [[NTQuickLook alloc] init];
	
	return shared;
}

- (void)showURLs:(NSArray*)urls 
	  zoomEffect:(BOOL)zoomEffect
	  fullScreen:(BOOL)fullScreen;
{	
	[[QLPreviewPanel sharedPreviewPanel] setURLs:urls];
	[self setUseZoomEffectsOnClose:zoomEffect];
	
	if (![self isOpen])
	{
		if (fullScreen)
			[[QLPreviewPanel sharedPreviewPanel] makeKeyAndGoFullscreenWithEffect:zoomEffect ? 2:1]; 
		else
			[[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFrontWithEffect:zoomEffect ? 2:1];
	}
}

- (BOOL)isOpen;
{
	return [[QLPreviewPanel sharedPreviewPanel] isOpen];
}

- (void)close;
{
	[[QLPreviewPanel sharedPreviewPanel] closeWithEffect:[self useZoomEffectsOnClose] ? 2:1];
}

- (void)setDelegate:(id)delegate;
{
	return [[[QLPreviewPanel sharedPreviewPanel] delegate] setDelegate:delegate];
}

- (NSRect)windowFrame;
{
	return [[QLPreviewPanel sharedPreviewPanel] frame];
}

@end

@implementation NTQuickLook (Private)

//---------------------------------------------------------- 
//  useZoomEffectsOnClose 
//---------------------------------------------------------- 
- (BOOL)useZoomEffectsOnClose
{
    return mUseZoomEffectsOnClose;
}

- (void)setUseZoomEffectsOnClose:(BOOL)flag
{
    mUseZoomEffectsOnClose = flag;
}

@end

// ----------------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------

typedef BOOL (*boolIMP)(id, SEL, ...);

static boolIMP gCanBecomeKeyWindowImp;
static boolIMP gCanBecomeMainWindowImp;

@implementation QLPreviewPanelHack

+ (void)install;
{
	gCanBecomeKeyWindowImp = (boolIMP)[NTObjcRuntimeTools replaceMethodImplementationWithSelectorOnClass:[QLPreviewPanel class]
																							 oldSelector:@selector(canBecomeKeyWindow)
																								newClass:self
																							 newSelector:@selector(hack_canBecomeKeyWindow)];
	gCanBecomeMainWindowImp = (boolIMP)[NTObjcRuntimeTools replaceMethodImplementationWithSelectorOnClass:[QLPreviewPanel class]
																							 oldSelector:@selector(canBecomeMainWindow)
																								newClass:self
																							 newSelector:@selector(hack_canBecomeMainWindow)];	
}

- (BOOL)hack_canBecomeKeyWindow;
{
	return NO;
}

- (BOOL)hack_canBecomeMainWindow;
{
	return NO;
}

@end

#endif

