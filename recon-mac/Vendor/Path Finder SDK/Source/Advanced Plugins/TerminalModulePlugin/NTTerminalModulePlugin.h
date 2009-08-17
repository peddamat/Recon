//
//  NTTerminalModulePlugin.h
//  TerminalModulePlugin
//
//  Created by Steve Gehrman on 5/6/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTModulePluginProtocol.h"

@class ITTerminalView;

@interface NTTerminalModulePlugin : NSObject
{
	id<NTPathFinderPluginHostProtocol> mHost;
	NSView* mView;
	ITTerminalView* mTerminalView;
}

@end
