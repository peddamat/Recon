//
//  NTKQueueSubscription.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTKQueueSubscription.h"
#import "NTKQueueMonitor.h"
#include <unistd.h>

@implementation NTKQueueSubscription

//---------------------------------------------------------- 
//  fd 
//---------------------------------------------------------- 
- (int)fd
{
    return mv_fd;
}

- (void)setFd:(int)theFd
{
    mv_fd = theFd;
}

@end

@implementation NTKQueueSubscription (MustSubclass)

- (void)subscribe;
{
	// pipe files hang open (this stuff needs to be in a thread in any case, needs fix)
	if (![[self desc] isPipe])
	{
		mv_fd = open([[self desc] fileSystemPath], O_EVTONLY, 0);
		if (mv_fd != -1)
			[[NTKQueueMonitor sharedInstance] add:self];
		else
			NSLog(@"-[%@ %@] open failed: %s\n%@", [self className], NSStringFromSelector(_cmd), strerror(errno), [[self desc] path]);
	}
	else
		NSLog(@"%@: not subscribing pipe", NSStringFromClass([self class]));
}

- (void)unsubscribe;
{
	if (mv_fd != -1)
	{
		[[NTKQueueMonitor sharedInstance] remove:self];

		close(mv_fd);
	}
}

@end

