//
//  NTOpenWithUIModelThread.h
//  OpenWithModulePlugin
//
//  Created by Steve Gehrman on 2/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTOpenWithUIModel;

@interface NTOpenWithUIModelThread : NTThreadRunnerParam 
{
	NTOpenWithUIModel* mModel;
	NSArray* mDescs;
}

+ (NTThreadRunner*)thread:(NSArray*)descs
				 delegate:(id<NTThreadRunnerDelegateProtocol>)delegate;

- (NTOpenWithUIModel *)model;

@end

