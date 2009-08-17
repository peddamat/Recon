//
//  NTFileEnvironment.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/8/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// short cut
#define FENV(x) [NTFileEnvironment x]

@interface NTFileEnvironment : NSObject {
}

+ (BOOL)debugFSWatcher;

	// set to yet to check for mem leaks
+ (BOOL)disableCache;

@end
