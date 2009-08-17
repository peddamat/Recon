//
//  NTVolumeMgr.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTVolumeSpec;

@interface NTVolumeMgr : NTSingletonObject 
{
	NTVolumeMgrState* state;
	NSArray* volumeSpecArray;
	NSMutableDictionary* volumeSpecDictionary;	
}

@property (retain) NTVolumeMgrState* state;
@property (retain, nonatomic) NSArray* volumeSpecArray;
@property (retain, nonatomic) NSMutableDictionary* volumeSpecDictionary;

- (NSArray*)volumes;
- (NSArray*)volumeSpecs;
- (NSArray*)freshVolumeSpecs;

// get a volumespec from the cache
- (NTVolumeSpec *)volumeSpecForRefNum:(FSVolumeRefNum)vRefNum;

@end
