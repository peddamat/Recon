//
//  NTSVNUtilities.h
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTSVNUtilities : NSObject {

}

+ (NSString *)htmlString:(NSString*)inString;
+ (NSString *)htmlStringWithPre:(NSString*)inString;

@end
