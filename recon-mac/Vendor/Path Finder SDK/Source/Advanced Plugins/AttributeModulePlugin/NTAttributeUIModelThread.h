//
//  NTAttributeUIModelThread.h
//  AttributeModulePlugin
//
//  Created by Steve Gehrman on 1/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTAttributeUIModel;

@interface NTAttributeUIModelThread : NTThreadRunnerParam 
{
	NTAttributeUIModel* mModel;
	NSArray* mDescs;
}

+ (NTThreadRunner*)thread:(NSArray*)descs
				 delegate:(id<NTThreadRunnerDelegateProtocol>)delegate;

- (NTAttributeUIModel *)model;

@end

