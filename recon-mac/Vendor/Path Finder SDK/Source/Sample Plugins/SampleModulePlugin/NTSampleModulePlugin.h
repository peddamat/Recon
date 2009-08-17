//
//  NTSampleModulePlugin.h
//  SampleModulePlugin
//
//  Created by Steve Gehrman on 5/6/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTModulePluginProtocol.h"
@class NTSampleUIController;

@interface NTSampleModulePlugin : NSObject
{
	id<NTPathFinderPluginHostProtocol> mHost;
	NSView* mView;
	NTSampleUIController* mUIController;
}

@end
