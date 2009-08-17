//
//  NTVolumeModifiedRebuildThread.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 8/2/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTVolumeModifiedRebuildThread : NTThreadRunnerParam
{
	NSArray *volumeWatchers;  
}

@property (retain) NSArray *volumeWatchers;

+ (NTThreadRunner*)thread:(id<NTThreadRunnerDelegateProtocol>)delegate;

@end
