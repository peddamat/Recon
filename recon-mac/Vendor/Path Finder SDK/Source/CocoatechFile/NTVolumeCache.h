//
//  NTVolumeCache.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 6/29/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTVolumeCache : NTSingletonObject
{
	NSMutableDictionary* cache;
}
@property (retain, nonatomic) NSMutableDictionary* cache;

- (NTVolume *)volumeForRefNum:(FSVolumeRefNum)vRefNum;

@end
