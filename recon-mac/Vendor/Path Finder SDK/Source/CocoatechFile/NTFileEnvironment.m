//
//  NTFileEnvironment.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/8/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFileEnvironment.h"

@implementation NTFileEnvironment

+ (BOOL)debugFSWatcher
{
	static int result = -1;
	
	if (result == -1)
	{
		result = 0;
		
		char * env = getenv("DEBUG_FSWATCHER");
		
		if (env && strlen(env))
		{
			NSString* s = [NSString stringWithUTF8String:env];
			
			if ([s isEqualToString:@"YES"] || [s isEqualToString:@"1"])
				result = 1;
		}
	}
	
	return (result == 1);
}

// set to yet to check for mem leaks
+ (BOOL)disableCache;
{
	static int result = -1;
	
	if (result == -1)
	{
		result = 0;
		
		char * env = getenv("DEBUG_DISABLECACHE");
		
		if (env && strlen(env))
		{
			NSString* s = [NSString stringWithUTF8String:env];
			
			if ([s isEqualToString:@"YES"] || [s isEqualToString:@"1"])
				result = 1;
		}
	}
	
	return (result == 1);
}

@end
