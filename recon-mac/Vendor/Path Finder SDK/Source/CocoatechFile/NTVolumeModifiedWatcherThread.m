//
//  NTVolumeModifiedWatcherThread.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 8/2/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import "NTVolumeModifiedWatcherThread.h"
#import "NTVolumeSpec.h"
#import "NTVolumeMgr.h"

@implementation NTVolumeModifiedWatcherThread

@synthesize previousCache;
@synthesize changedVolumeSpecs, freespaceCache;

+ (NTThreadRunner*)thread:(id<NTThreadRunnerDelegateProtocol>)delegate
				  previousCache:(NSDictionary*)thePreviousCache;
{
    NTVolumeModifiedWatcherThread* param = [[[NTVolumeModifiedWatcherThread alloc] init] autorelease];
	
	param.previousCache = thePreviousCache;
	
	return [NTThreadRunner thread:param
						 priority:.5
						 delegate:delegate];	
}

- (void)dealloc
{
	self.previousCache = nil;
	self.freespaceCache = nil;
	self.changedVolumeSpecs = nil;
    [super dealloc];
}

@end

@implementation NTVolumeModifiedWatcherThread (Thread)

- (BOOL)doThreadProc;
{	
	NSMutableDictionary* freeSpaceDict  = [NSMutableDictionary dictionary];
	NSArray* theVolumes = [[NTVolumeMgr sharedInstance] freshVolumeSpecs];
	NSMutableArray *theChangedVolumeSpecs = [NSMutableArray array];
	
	for (NTVolumeSpec* volumeSpec in theVolumes)
	{
		NSNumber* newFreespace = [NSNumber numberWithUnsignedLongLong:[volumeSpec freeBytes]];
		[freeSpaceDict setObject:newFreespace forKey:[[volumeSpec mountPoint] dictionaryKey]];
		
		// only compare to what's in previous Cache
		if (self.previousCache)
		{
			// does this volume exist in our cache? If not, we are changed
			NSNumber* oldFreespace = [self.previousCache objectForKey:[[volumeSpec mountPoint] dictionaryKey]];
			if (oldFreespace)
			{
				if (abs([newFreespace unsignedLongLongValue] - [oldFreespace unsignedLongLongValue]) > (1024*512)) // must be greater than .5MB
					[theChangedVolumeSpecs addObject:volumeSpec];
			}
		}
	}
	
	self.freespaceCache = [NSDictionary dictionaryWithDictionary:freeSpaceDict];
	self.changedVolumeSpecs = [NSArray arrayWithArray:theChangedVolumeSpecs];
	
	return (![[self helper] killed]);
}

@end
