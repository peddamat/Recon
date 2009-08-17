//
//  NTSizeUIView.m
//  SizeModulePlugin
//
//  Created by Steve Gehrman on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTSizeUIView.h"


@implementation NTSizeUIView

@synthesize drawsBackground;

- (void)drawRect:(NSRect)rect;
{
	if ([self drawsBackground])
	{
		[[NSColor whiteColor] set];
		[NSBezierPath fillRect:rect];
	}
}

- (BOOL)isOpaque;
{
	if ([self drawsBackground])
		return YES;
	
	return NO;
}

@end
