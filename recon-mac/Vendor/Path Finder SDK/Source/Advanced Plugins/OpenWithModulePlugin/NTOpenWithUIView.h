//
//  NTOpenWithUIView.h
//  OpenWithModulePlugin
//
//  Created by Steve Gehrman on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTOpenWithUIView : NSView
{
	BOOL mDrawsBackground;
}

- (BOOL)drawsBackground;
- (void)setDrawsBackground:(BOOL)flag;

@end
