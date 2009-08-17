//
//  NTFileRep.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/30/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTFileRep : NSObject 
{
	UInt32 nodeID;
	NSString* displayName;

	BOOL isVolume;
	FSVolumeRefNum volumeRefNum;  // nodeID is useless for volumes, compare volumeRefNum
}

@property (assign) UInt32 nodeID;
@property (assign) BOOL isVolume;
@property (assign) FSVolumeRefNum volumeRefNum;
@property (retain) NSString* displayName;

+ (NTFileRep*)rep:(NTFileDesc*)theDesc;
+ (NSArray*)reps:(NSArray*)theDescs;

- (BOOL)matchesNodeID:(NTFileDesc*)theDesc;
- (BOOL)matchesDisplayName:(NTFileDesc*)theDesc;
@end
