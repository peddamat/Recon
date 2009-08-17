//
//  NTSampleModuleThread.h
//  SampleModulePlugin
//
//  Created by Steve Gehrman on 2/20/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTSampleModuleThread;

@protocol NTSampleModuleThreadDelegate <NSObject>
// called on main thread
- (void)thread:(NTSampleModuleThread*)thread result:(NSArray*)result;
@end

@interface NTSampleModuleThread : NSObject 
{
	id<NTSampleModuleThreadDelegate> mDelegate;
	NSArray* mSelection;
	
	BOOL mStopped;
}

+ (NTSampleModuleThread*)thread:(NSArray*)selection delegate:(id<NTSampleModuleThreadDelegate>)delegate;
- (void)clearDelegate;

- (NSArray *)selection;
- (void)setSelection:(NSArray *)theSelection;

@end
