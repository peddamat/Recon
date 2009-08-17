//
//  NTVolumeCache.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 6/29/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTVolumeCache.h"
#import "NTVolume.h"

@interface NTVolumeCache (Private)
- (NTVolume*)volumeFromCache:(NSNumber*)volumeRefNum;
@end

@implementation NTVolumeCache

NTSINGLETONOBJECT_STORAGE;
NTSINGLETON_INITIALIZE;

@synthesize cache;

- (id)init;
{
	self = [super init];
	
	self.cache = [NSMutableDictionary dictionary];
	
	return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	self.cache = nil;
	
    [super dealloc];
}

- (NTVolume *)volumeForRefNum:(FSVolumeRefNum)vRefNum;
{
	NSNumber* volumeRefNum = [NSNumber numberWithShort:vRefNum];
	
    return [self volumeFromCache:volumeRefNum];
}

@end

@implementation NTVolumeCache (Private)

- (NTVolume*)volumeFromCache:(NSNumber*)volumeRefNum;
{
	NTVolume *result = nil;
	
	@synchronized(self) {
		result = [self.cache objectForKey:volumeRefNum];
		
		if (!result)
		{
			result = [NTVolume volumeWithRefNum:[volumeRefNum intValue]];
			[self.cache setObject:result forKey:volumeRefNum];
		}
	}
	
	return result;
}

@end