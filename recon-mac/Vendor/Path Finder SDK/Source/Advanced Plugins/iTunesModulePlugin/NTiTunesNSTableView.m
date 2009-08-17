//
//  NTiTunesNSTableView.m
//  iTunesModulePlugin
//
//  Created by Steve Gehrman on 7/18/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTiTunesNSTableView.h"

@implementation NTiTunesNSTableView

// had to subclass NSTableView just to do this.  DUH!
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag;
{
	return NSDragOperationCopy;	
}

@end

@implementation NTiTunesSourceListTableView

// this background color only shows when animating, so removing it might seem to work
- (void)drawRect:(NSRect)rect;
{
	[self setBackgroundColor:[NTStandardColors sourceListBackgroundColor:[[self window] dimControls]]];
	
	[super drawRect:rect];
}

@end



