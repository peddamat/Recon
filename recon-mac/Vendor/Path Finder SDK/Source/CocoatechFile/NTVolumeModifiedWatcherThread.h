//
//  NTVolumeModifiedWatcherThread.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 8/2/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTVolumeModifiedWatcherThread : NTThreadRunnerParam
{
	NSDictionary* previousCache;
	
	NSArray* changedVolumeSpecs;
	NSDictionary *freespaceCache;  
}

@property (retain) NSDictionary* previousCache;
@property (retain) NSDictionary *freespaceCache;
@property (retain) NSArray* changedVolumeSpecs;

+ (NTThreadRunner*)thread:(id<NTThreadRunnerDelegateProtocol>)delegate
			previousCache:(NSDictionary*)thePreviousCache;

@end
