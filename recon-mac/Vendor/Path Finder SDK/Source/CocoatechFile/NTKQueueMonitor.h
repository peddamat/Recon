//
//  NTKQueueMonitor.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 9/5/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTFNMonitor.h"

@class NTKQueueSubscription;

@interface NTKQueueMonitor : NTFSMonitor 
{
	int mv_kqueueFD;
	NSPipe* mv_pipe;
}

// kill running thread, no longer valid 
- (void)kill;

@end
