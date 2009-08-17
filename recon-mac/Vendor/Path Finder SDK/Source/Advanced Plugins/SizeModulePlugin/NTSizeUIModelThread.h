//
//  NTSizeUIModelThread.h
//  SizeModulePlugin
//
//  Created by Steve Gehrman on 2/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTSizeUIModel;

@interface NTSizeUIModelThread : NTThreadRunnerParam 
{
	NTSizeUIModel* mModel;
	NSArray* mDescs;
}

+ (NTThreadRunner*)thread:(NSArray*)descs
				 delegate:(id<NTThreadRunnerDelegateProtocol>)delegate;

- (NTSizeUIModel *)model;
- (NSArray *)descs;

@end

