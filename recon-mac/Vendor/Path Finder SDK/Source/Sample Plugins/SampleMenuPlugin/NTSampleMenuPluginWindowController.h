//
//  NTSampleMenuPluginWindowController.h
//  Path Finder
//
//  Created by Steve Gehrman on Fri Mar 07 2003.
//  Copyright (c) 2003 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol NTPathFinderPluginHostProtocol;

@interface NTSampleMenuPluginWindowController : NSWindowController
{
	IBOutlet id mObjectController;
	
    id<NTPathFinderPluginHostProtocol> mHost;
	
	NSMutableDictionary* mModel;
}

+ (id)window:(id<NTPathFinderPluginHostProtocol>)host;

@end
