//
//  NTFSDeleteThread.m
//  CocoatechFile
//
//  Created by sgehrman on Tue Jun 05 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NTFSDeleteThread.h"
#import "NTFileDeleter.h"
#import "NTFilePreflightTests.h"

@interface NTFSDeleteThread (Private)
- (void)startThread;

- (id<NTFSDeleteThreadDelegateProtocol>)delegate;
- (void)setDelegate:(id<NTFSDeleteThreadDelegateProtocol>)theDelegate;

- (NTFileDesc *)directory;
- (void)setDirectory:(NTFileDesc *)theDirectory;

- (NTDeleteSecurityLevel)securityLevel;
- (void)setSecurityLevel:(NTDeleteSecurityLevel)theSecurityLevel;

- (NSArray *)descs;
- (void)setDescs:(NSArray *)theDescs;

- (NTThreadHelper *)threadHelper;
- (void)setThreadHelper:(NTThreadHelper *)theThreadHelper;
@end

@interface NTFSDeleteThread (Protocols)  <NTFileDeleterDelegateProtocol>
@end

@implementation NTFSDeleteThread

- (id)init;
{
	self = [super init];
	
	[self setThreadHelper:[NTThreadHelper threadHelper]];

	return self;
}

- (void)dealloc;
{
	if ([self delegate])
		[NSException raise:@"must call clear delegate" format:@"%@", NSStringFromClass([self class])];

    [self setDirectory:nil];
    [self setDescs:nil];
	[self setThreadHelper:nil];

	[super dealloc];
}

+ (NTFSDeleteThread*)deleteDescs:(NSArray*)descs
				   securityLevel:(NTDeleteSecurityLevel)securityLevel
						 delegate:(id<NTFSDeleteThreadDelegateProtocol>)delegate;
{
	NTFSDeleteThread* result = [[NTFSDeleteThread alloc] init];
	
	[result setDelegate:delegate];
	[result setDescs:descs];
	[result setSecurityLevel:securityLevel];
	[result startThread];

	return [result autorelease];
}

+ (NTFSDeleteThread*)deleteDirectoryContents:(NTFileDesc*)directory
							   securityLevel:(NTDeleteSecurityLevel)securityLevel
									delegate:(id<NTFSDeleteThreadDelegateProtocol>)delegate;
{
	NTFSDeleteThread* result = [[NTFSDeleteThread alloc] init];
	
	[result setDelegate:delegate];
	[result setDirectory:directory];
	[result setSecurityLevel:securityLevel];
	[result startThread];
	
	return [result autorelease];	
}

- (void)clearDelegate;
{
	[self setDelegate:nil];
}

- (void)stopThread;
{
	[[self threadHelper] setKilled:YES];

	// call this incase the thread is blocked
	[[self threadHelper] resume];
}

- (void)resumeThread;  // paused internally by scanThreadSkip
{
	[[self threadHelper] resume]; 
}

@end

@implementation NTFSDeleteThread (Private)

//---------------------------------------------------------- 
//  securityLevel 
//---------------------------------------------------------- 
- (NTDeleteSecurityLevel)securityLevel
{
    return mSecurityLevel;
}

- (void)setSecurityLevel:(NTDeleteSecurityLevel)theSecurityLevel
{
    mSecurityLevel = theSecurityLevel;
}

//---------------------------------------------------------- 
//  directory 
//---------------------------------------------------------- 
- (NTFileDesc *)directory
{
    return mDirectory; 
}

- (void)setDirectory:(NTFileDesc *)theDirectory
{
    if (mDirectory != theDirectory) {
        [mDirectory release];
        mDirectory = [theDirectory retain];
    }
}

//---------------------------------------------------------- 
//  descs 
//---------------------------------------------------------- 
- (NSArray *)descs
{
    return mDescs; 
}

- (void)setDescs:(NSArray *)theDescs
{
    if (mDescs != theDescs) {
        [mDescs release];
        mDescs = [theDescs retain];
    }
}

- (void)startThread;
{
	[NSThread detachNewThreadSelector:@selector(threadProc:) toTarget:self withObject:nil];
}

//---------------------------------------------------------- 
//  delegate 
//---------------------------------------------------------- 
- (id<NTFSDeleteThreadDelegateProtocol>)delegate
{
    return mv_delegate; 
}

- (void)setDelegate:(id<NTFSDeleteThreadDelegateProtocol>)theDelegate
{
    if (mv_delegate != theDelegate) {
        mv_delegate = theDelegate;  // not retained
    }
}

//---------------------------------------------------------- 
//  threadHelper 
//---------------------------------------------------------- 
- (NTThreadHelper *)threadHelper
{
    return mv_threadHelper; 
}

- (void)setThreadHelper:(NTThreadHelper *)theThreadHelper
{
    if (mv_threadHelper != theThreadHelper) {
        [mv_threadHelper release];
        mv_threadHelper = [theThreadHelper retain];
    }
}

@end

@implementation NTFSDeleteThread (Thread)

- (void)threadProc:(id)param
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// make it as fast as possible
    [NSThread setThreadPriority:1.0];

	NSArray* deleteDescs=nil;
	
	// we either have a directory to delete it's contents, or a list of files to delete which could be in different directories
	if ([self directory])
		deleteDescs = [[self directory] directoryContentsForDelete];
	else if ([self descs]) 
	{
		[self setDescs:[NTFilePreflightTests removeChildItemsFromSources:[self descs]]];
		deleteDescs = [self descs];
	}
		
	NTFileDeleter *deleter = [[NTFileDeleter deleter:self securityLevel:[self securityLevel]] retain];
	NTFileDesc* desc;
	
	for (desc in deleteDescs)
	{
		if ([desc isValid] && ![desc isVolume])
			[deleter deleteDesc:desc];
				
		if ([[self threadHelper] killed])
			break;
	}
	
	[deleter clearDelegate];
	[deleter release];
		
	[[self delegate] deleteThreadDone:self];
	
    [pool release];
}

@end
  
@implementation NTFSDeleteThread (Protocols)

- (void)sendErrorOnMainThread:(NSArray *)params;
{
	if ([params count] == 2)
	{
		[[self delegate] deleteThreadError:self
									  item:[params objectAtIndex:0]
									 error:[[params objectAtIndex:1] intValue]];
	}
}	

// ----------------------------------------------------------------
// return NO to stop the copy
- (BOOL)deleter:(NTFileDeleter*)deleter displayErrorAtPath:(NTFileDesc*)desc error:(OSStatus)error;
{		
	[[self threadHelper] pause];
	{
		// we must do this since it's modal and we can't pause our thread after if it doesn't return right away
		[self performSelectorOnMainThread:@selector(sendErrorOnMainThread:) withObject:[NSArray arrayWithObjects:desc, [NSNumber numberWithInt:error], nil]];
	}
	[[self threadHelper] wait];
	
	return ![[self threadHelper] killed];
}

- (BOOL)deleter:(NTFileDeleter*)deleter deleteProgress:(NTFileDesc*)desc;
{
	if ([[self threadHelper] timeHasElapsed])
	{
		[[self delegate] deleteThreadProgress:self
										 path:[desc path]
									   volume:[desc mountPoint]];
	}
	
	return ![[self threadHelper] killed];
}

@end
