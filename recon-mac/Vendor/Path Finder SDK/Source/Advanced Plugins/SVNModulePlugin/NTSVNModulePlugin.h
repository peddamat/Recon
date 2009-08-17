//
//  NTSVNModulePlugin.h
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 5/6/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTModulePluginProtocol.h"
@class NTSVNUIController;

@interface NTSVNModulePlugin : NSObject
{
	NSView* mView;
	NTSVNUIController* UIController;
}

@property (retain) NTSVNUIController* UIController;
@end
