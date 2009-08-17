//
//  NTSampleUIController.h
//  SampleModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTSampleModuleThread;

@interface NTSampleUIController : NSObject 
{
	IBOutlet NSView* mContentView;
	IBOutlet NSObjectController* mObjectController;
	
	NSView* mView;
	NSMutableDictionary* mModel;
	
	NTSampleModuleThread* mThread;
}
+ (NTSampleUIController*)controller;

- (void)selectionUpdated:(NSArray*)items;

- (void)invalidate; // called so we can be dealloced, retained by objectController
- (NSView *)view;

@end
