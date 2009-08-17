//
//  NTAttributeModulePlugin.h
//  AttributeModulePlugin
//
//  Created by Steve Gehrman on 5/6/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTModulePluginProtocol.h"

@class NTAttributeUIController;

@interface NTAttributeModulePlugin : NSObject
{
	id<NTPathFinderPluginHostProtocol> host;
	NSView* mView;
	NTAttributeUIController* mUIController;
}

@property (retain) id<NTPathFinderPluginHostProtocol> host;

@end
