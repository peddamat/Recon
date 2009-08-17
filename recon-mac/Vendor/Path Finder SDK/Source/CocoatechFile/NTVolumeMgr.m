//
//  NTVolumeMgr.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTVolumeMgr.h"
#import "NTVolumeSpec.h"
#import "NTVolumeNotificationMgr.h"
#import "NTVolumeMgrState.h"
#import "NTVolumeModifiedWatcher.h"

@interface NTVolumeMgr (Private)
- (void)refreshStateIfInvalid;
- (void)updateCache:(NSArray*)volumeSpecs;

+ (NSMutableArray*)mountedVolumeSpecsUsingCocoa;
+ (NSMutableArray*)mountedVolumeSpecsUsingCarbon;

// returns NTVolumeSpec
+ (NSArray*)mountedVolumeSpecs;
@end

@implementation NTVolumeMgr

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

@synthesize state;
@synthesize volumeSpecArray;
@synthesize volumeSpecDictionary;

- (id)init;
{
	self = [super init];
	
	// start this up
	[self performDelayedSelector:@selector(startupVolumeModifiedWatcher) withObject:nil];
	
	return self;
}

- (void)dealloc;
{
	self.state = nil;
	self.volumeSpecArray = nil;
	self.volumeSpecDictionary = nil;
	
	[super dealloc];
}

- (NSArray*)volumes;
{
	NSMutableArray* result = [NSMutableArray array];
	
	for (NTVolumeSpec *vDesc in [self volumeSpecs])
		[result addObject:[vDesc mountPoint]];
	
	return result;
}

- (NSArray*)volumeSpecs;
{
	NSArray *result = nil;
	BOOL updateCache=NO;
	
	@synchronized(self)	{
		[self refreshStateIfInvalid];
		
		if (!self.volumeSpecArray)
		{
			self.volumeSpecArray = [NTVolumeMgr mountedVolumeSpecs];
			updateCache = YES;
		}
		
		result = [NSArray arrayWithArray:self.volumeSpecArray];
		
		// update the cache
		if (updateCache)
			[self updateCache:result];
	}
	
	return result;
}

- (NSArray*)freshVolumeSpecs;
{
	return [NTVolumeMgr mountedVolumeSpecs];
}

- (NTVolumeSpec *)volumeSpecForRefNum:(FSVolumeRefNum)vRefNum;
{
	NSNumber* key = [NSNumber numberWithShort:vRefNum];
	NTVolumeSpec* result;
	
	@synchronized(self)	{
		[self refreshStateIfInvalid];
		
		result = [[[self.volumeSpecDictionary objectForKey:key] retain] autorelease];
		if (!result)
		{
			result = [NTVolumeSpec volumeWithRefNum:vRefNum];
			if (result)
				[self.volumeSpecDictionary setObject:result forKey:key];
		}
	}
	
	return result;
}

@end

@implementation NTVolumeMgr (Private)

- (void)startupVolumeModifiedWatcher;
{
	[NTVolumeModifiedWatcher sharedInstance];
}

// returns NTVolumeSpec
+ (NSArray*)mountedVolumeSpecs;
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:10];

	NSMutableArray *cocoaVolumes = [self mountedVolumeSpecsUsingCocoa];
	for (NTVolumeSpec *theSpec in cocoaVolumes)
	{
		// expand drives never appear in the Cocoa list, but if the bug is fixed at some point, we don't want to break, so only copy non expand drives
		if (![theSpec isExpandrive])
			[result addObject:theSpec];
	}
	
	NSMutableArray* expandDrives = [self mountedVolumeSpecsUsingCarbon];
	for (NTVolumeSpec *theSpec in expandDrives)
	{
		// add only expandrives since they show up in the carbon list, but don't add anything else to avoid issues
		if ([theSpec isExpandrive])
			[result addObject:theSpec];
	}
	
	return result;
}

+ (NSMutableArray*)mountedVolumeSpecsUsingCocoa;
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:10];

	NSArray *mountedVols = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths]; 
	for (NSString *mountPoint in mountedVols)
	{
		NTFileDesc* desc = [NTFileDesc descNoResolve:mountPoint];
		
		if ([desc isValid])
		{
			NTVolumeSpec* volumeSpec = [NTVolumeSpec volumeWithMountPoint:desc];
			
			if ([volumeSpec isUserVolume])
				[result addObject:volumeSpec];
		}
	}	
	
	return result;
}

+ (NSMutableArray*)mountedVolumeSpecsUsingCarbon;
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:10];

	FSRef ref;
	OSErr err=noErr;
	
	for (ItemCount volumeIndex = 1; err == noErr || err != nsvErr; volumeIndex++) 
	{
		err = FSGetVolumeInfo(kFSInvalidVolumeRefNum,
							  volumeIndex,
							  NULL,
							  kFSVolInfoNone,
							  NULL,
							  NULL,
							  &ref); 
		
		if (err == noErr)
		{
			NTFileDesc* desc = [NTFileDesc descFSRef:&ref];
			
			if ([desc isValid])
			{
				NTVolumeSpec* volumeSpec = [NTVolumeSpec volumeWithMountPoint:desc];
				
				if ([volumeSpec isUserVolume])
					[result addObject:volumeSpec];
			}				
		}
	}	
	
	return result;
}

- (void)refreshStateIfInvalid;
{
	// first time called, set initial state
	if (self.state)
	{
		if (self.state.changed)
		{		
			self.state = nil;
			self.volumeSpecDictionary = nil;
			self.volumeSpecArray = nil;
		}
	}
	
	if (!self.state)
		self.state = [NTVolumeMgrState state];
	
	if (!self.volumeSpecDictionary)
		self.volumeSpecDictionary = [NSMutableDictionary dictionary];
}

- (void)updateCache:(NSArray*)volumeSpecs;
{	
	[self.volumeSpecDictionary removeAllObjects];
	
	for (NTVolumeSpec* volumeSpec in volumeSpecs)
		[self.volumeSpecDictionary setObject:volumeSpec forKey:[NSNumber numberWithInt:[volumeSpec volumeRefNum]]];	
}

@end

