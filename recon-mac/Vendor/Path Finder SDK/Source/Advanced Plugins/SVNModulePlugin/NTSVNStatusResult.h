//
//  NTSVNStatusResult.h
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 12/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTSVNStatusResult : NSObject 
{
	NSString* mXML;

	NSArray* mItems; // array of NTSVNStatusItem
	NSString* mHTML;
}

// send output from task, parse and hold results
+ (NTSVNStatusResult*)result:(NSString*)res;

- (BOOL)updateForCommand:(NSString*)command path:(NSString*)path;

- (NSString *)HTML;

@end
