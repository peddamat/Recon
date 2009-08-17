//
//  NTKQueueSubscription.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTFSSubscription.h"

@interface NTKQueueSubscription : NTFSSubscription
{
	int mv_fd;
}

- (int)fd;
- (void)setFd:(int)theFd;

@end
