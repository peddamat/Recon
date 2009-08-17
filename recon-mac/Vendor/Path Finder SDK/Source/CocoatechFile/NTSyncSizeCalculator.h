//
//  NTSyncSizeCalculator.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/31/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFSSize;

@interface NTSyncSizeCalculator : NSObject 
{
	NTFileDesc* desc;
	NSOperation* operation;
	NSArray* cachedSizes;
	BOOL subfolders;
	BOOL supportsForks; // just caching this for speed
	FSVolumeRefNum volumeRefNum; // make sure we don't go across volumes "/Volumes" for example
}

@property (retain) NTFileDesc* desc;
@property (retain) NSOperation* operation;
@property (retain) NSArray* cachedSizes;
@property (assign, nonatomic) BOOL subfolders;  // non atomic for speed
@property (assign, nonatomic) BOOL supportsForks;  // non atomic for speed
@property (assign, nonatomic) FSVolumeRefNum volumeRefNum; // non atomic for speed

+ (NTFSSize*)sizeAndValenceForDesc:(NTFileDesc*)theDesc
						subfolders:(BOOL)theSubfolders
						 operation:(NSOperation*)theOperation
					   cachedSizes:(NSArray*)theCachedSizes;

@end
