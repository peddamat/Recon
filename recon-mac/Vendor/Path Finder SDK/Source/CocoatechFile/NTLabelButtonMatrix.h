//
//  NTLabelButtonMatrix.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 6/22/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTLabelButtonMatrix : NSMatrix 
{
	NSMutableArray* mTrackingAreas;
	
	NSTextField *mTextField;
}

@end
