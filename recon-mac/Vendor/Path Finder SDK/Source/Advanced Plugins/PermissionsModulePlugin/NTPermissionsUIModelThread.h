//
//  NTPermissionsUIModelThread.h
//  PermissionsModulePlugin
//
//  Created by Steve Gehrman on 1/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTPermissionsUIModel;

@interface NTPermissionsUIModelThread : NTThreadRunnerParam 
{
	NTPermissionsUIModel* model;
	NSArray* descs;
}

@property (retain) NTPermissionsUIModel* model;
@property (retain) NSArray* descs;

+ (NTThreadRunner*)thread:(NSArray*)descs
				 delegate:(id<NTThreadRunnerDelegateProtocol>)delegate;

@end

