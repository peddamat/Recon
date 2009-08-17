//
//  NTFileListMonitor.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/9/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTFileListMonitor.h"
#import "NTFileListMonitorThread.h"
#import "NTFSWatcher.h"

@interface NTFileListMonitor (Private)
- (NTFSWatcher *)watcher;
- (void)setWatcher:(NTFSWatcher *)theWatcher;

- (NTThreadRunner *)threadRunner;
- (void)setThreadRunner:(NTThreadRunner *)theThreadRunner;

- (void)watchList;
- (void)scanList;
@end

@interface NTFileListMonitor (Protocols) <NTFSWatcherDelegateProtocol, NTThreadRunnerDelegateProtocol>
@end

@implementation NTFileListMonitor

@synthesize descs, delegate;

+ (NTFileListMonitor*)monitor:(NSArray*)descs delegate:(id<NTFileListMonitorDelegate>)delegate;
{
	NTFileListMonitor* result = [[NTFileListMonitor alloc] init];
	
	[result setDescs:descs];
	[result setDelegate:delegate];
	[result setDescs:descs];
	
	// start watching
	[result watchList];
	
	// initial scan
	[result scanList];
	
	return [result autorelease];
}

- (void)clearDelegate;
{
	[self setDelegate:nil];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	if ([self delegate])
		[NSException raise:@"must call clearDelegate" format:@"%@", NSStringFromClass([self class])];
	
    [self setWatcher:nil];
	[self setThreadRunner:nil];
    [self setDescs:nil];

    [super dealloc];
}

- (NTFileDesc*)desc;
{
	NSArray* theDescs = [self descs];
	
	if ([theDescs count])
		return [theDescs objectAtIndex:0];	
	
	return nil;
}

@end

@implementation NTFileListMonitor (Private)

//---------------------------------------------------------- 
//  threadRunner 
//---------------------------------------------------------- 
- (NTThreadRunner *)threadRunner
{
    return mThreadRunner; 
}

- (void)setThreadRunner:(NTThreadRunner *)theThreadRunner
{
    if (mThreadRunner != theThreadRunner)
    {
        [mThreadRunner clearDelegate];
		
        [mThreadRunner release];
        mThreadRunner = [theThreadRunner retain];
    }
}

//---------------------------------------------------------- 
//  watcher 
//---------------------------------------------------------- 
- (NTFSWatcher *)watcher
{
	if (!mWatcher)
		[self setWatcher:[NTFSWatcher watcher:self]];
	
    return mWatcher; 
}

- (void)setWatcher:(NTFSWatcher *)theWatcher
{
    if (mWatcher != theWatcher)
    {
		[mWatcher clearDelegate];
		
        [mWatcher release];
        mWatcher = [theWatcher retain];
    }
}

- (void)scanList;
{
	[self setThreadRunner:[NTFileListMonitorThread thread:[self descs] delegate:self]];
}

- (void)watchList;
{
	[[self watcher] watchItems:[self descs]];
}

@end

@implementation NTFileListMonitor (Protocols)

// NTFSWatcherDelegateProtocol

- (void)watcher:(NTFSWatcher*)watcher itemsChanged:(NSArray*)descs;
{
	[self scanList];
}

- (void)threadRunner_complete:(NTThreadRunner*)threadRunner;
{
	if (threadRunner == [self threadRunner])
	{
		NTFileListMonitorThread* param = (NTFileListMonitorThread*)[threadRunner param];
		
		[self setDescs:[param descs]];

		if ([param descsRemoved])
			[self watchList];
		
		if ([param descsModified])
			[[self delegate] fileListMonitor_updated:self];
	}
}

@end
