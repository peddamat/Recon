//
//  NTVolumeMgrState.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 3/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTVolumeMgrState.h"

@interface NTVolumeMgrState (Private)
+ (UInt64)sharedBuildNumber:(BOOL)increment;
@end

@implementation NTVolumeMgrState

@synthesize buildNumber;

+ (NTVolumeMgrState*)state;
{
	NTVolumeMgrState *result = [[NTVolumeMgrState alloc] init];
    
	result.buildNumber = [NTVolumeMgrState sharedBuildNumber:NO];
    
    return [result autorelease];
}

+ (void)incrementBuild;
{
	[self sharedBuildNumber:YES];
}

- (BOOL)changed;
{
    return (self.buildNumber != [NTVolumeMgrState sharedBuildNumber:NO]);
}

@end

@implementation NTVolumeMgrState (Private)

+ (UInt64)sharedBuildNumber:(BOOL)increment;
{
	static UInt64 shared = 0;
	
	if (increment)
		shared++;
	
	return shared;
}

@end

