//
//  NTFSDeleteThread.h
//  CocoatechFile
//
//  Created by sgehrman on Tue Jun 05 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTProgressBar, NTFSDeleteThread;

@protocol NTFSDeleteThreadDelegateProtocol <NSObject>

- (void)deleteThreadDone:(NTFSDeleteThread*)thread;

- (void)deleteThreadProgress:(NTFSDeleteThread*)thread 
						path:(NSString*)path
					  volume:(NTFileDesc*)volume;

- (void)deleteThreadError:(NTFSDeleteThread*)thread 
						item:(NTFileDesc*)item
					error:(OSStatus)error;

@end

@interface NTFSDeleteThread : NSObject
{
	id<NTFSDeleteThreadDelegateProtocol> mv_delegate;

	NTDeleteSecurityLevel mSecurityLevel;

	NSArray* mDescs;
	NTFileDesc* mDirectory;
	
	NTThreadHelper* mv_threadHelper;
}

+ (NTFSDeleteThread*)deleteDescs:(NSArray*)descs
				   securityLevel:(NTDeleteSecurityLevel)securityLevel
						 delegate:(id<NTFSDeleteThreadDelegateProtocol>)delegate;

+ (NTFSDeleteThread*)deleteDirectoryContents:(NTFileDesc*)directory
							   securityLevel:(NTDeleteSecurityLevel)securityLevel
									delegate:(id<NTFSDeleteThreadDelegateProtocol>)delegate;

- (void)clearDelegate;

- (void)stopThread;
- (void)resumeThread;  // paused internally by scanThreadSkip

@end
