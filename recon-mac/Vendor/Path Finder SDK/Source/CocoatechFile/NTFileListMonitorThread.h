//
//  NTFileListMonitorThread.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/9/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTFileListMonitorThread : NTThreadRunnerParam
{
    NSArray* descs;
    BOOL descsRemoved;
	BOOL descsModified;
}

@property (retain) NSArray* descs;
@property (assign) BOOL descsRemoved;
@property (assign) BOOL descsModified;

+ (NTThreadRunner*)thread:(NSArray*)descs
				 delegate:(id<NTThreadRunnerDelegateProtocol>)delegate;

@end
