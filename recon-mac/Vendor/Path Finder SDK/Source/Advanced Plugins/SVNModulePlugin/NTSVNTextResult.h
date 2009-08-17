//
//  NTSVNTextResult.h
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTSVNTextResult : NSObject 
{
	NSString* mResult;
	
	NSString* mHTML;
}

// send output from task, parse and hold results
+ (NTSVNTextResult*)result:(NSString*)res;

- (NSString *)HTML;
- (void)setHTML:(NSString *)theHTML;

@end
