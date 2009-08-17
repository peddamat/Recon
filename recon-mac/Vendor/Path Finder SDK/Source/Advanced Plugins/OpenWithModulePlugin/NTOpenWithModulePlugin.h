//
//  NTOpenWithModulePlugin.h
//  OpenWithModulePlugin
//
//  Created by Steve Gehrman on 5/6/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTModulePluginProtocol.h"

@class NTOpenWithUIController;

@interface NTOpenWithModulePlugin : NSObject
{
	id<NTPathFinderPluginHostProtocol> mHost;
	NSView* mView;
	NTOpenWithUIController* mUIController;
}

@end
