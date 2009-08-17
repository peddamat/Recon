//
//  NotesTableView.m
//  recon
//
//  Created by Sumanth Peddamatham on 8/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NotesTableView.h"


@implementation NotesTableView

@synthesize alternatingColors;

-(void)awakeFromNib
{
   // Insert initialization code here...
   self.alternatingColors = [NSArray arrayWithObjects:
                             [NSColor colorWithCalibratedRed:248.0/255.0 green:244/255.0 blue:200/255.0 alpha:1.0],
                             [NSColor colorWithCalibratedRed:248/255.0 green:245/255.0 blue:180/255.0 alpha:1.0],
                             nil];
}

//- (void)drawBackgroundInClipRect:(NSRect)clipRect;
//{
//	// make sure we do nothing so the drawRow method's drawing will take effect
//   [super drawBackgroundInClipRect:clipRect];
//}

- (void)drawRow:(int)row clipRect:(NSRect)rect;
{
	[[alternatingColors objectAtIndex:(row % 2)] setFill];
	NSRectFill([self rectOfRow:row]);
	
	[super drawRow:row clipRect:rect];
}

@end
