//
//  NTSampleModuleThread.m
//  SampleModulePlugin
//
//  Created by Steve Gehrman on 2/20/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTSampleModuleThread.h"
#import "NTModulePluginProtocol.h"

@interface NTSampleModuleThread (Private)
- (id<NTSampleModuleThreadDelegate>)delegate;
- (void)setDelegate:(id<NTSampleModuleThreadDelegate>)theDelegate;

- (BOOL)stopped;
- (void)setStopped:(BOOL)flag;
@end

@implementation NTSampleModuleThread

+ (NTSampleModuleThread*)thread:(NSArray*)selection delegate:(id<NTSampleModuleThreadDelegate>)delegate;
{
	NTSampleModuleThread *result = [[NTSampleModuleThread alloc] init];
	
	[result setDelegate:delegate];
	[result setSelection:selection];
	
	[NSThread detachNewThreadSelector:@selector(threadProc) toTarget:result withObject:nil];	
	
	return [result autorelease];
}

- (void)clearDelegate;
{
	[self setDelegate:nil];
	[self setStopped:YES];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setSelection:nil];
    [super dealloc];
}

//---------------------------------------------------------- 
//  selection 
//---------------------------------------------------------- 
- (NSArray *)selection
{
    return mSelection; 
}

- (void)setSelection:(NSArray *)theSelection
{
    if (mSelection != theSelection)
    {
        [mSelection release];
        mSelection = [theSelection retain];
    }
}

//---------------------------------------------------------- 
//  stopped 
//---------------------------------------------------------- 
- (BOOL)stopped
{
	BOOL result = NO;
	
	// called from thread
	@synchronized(self) {
		result = mStopped;
	}
	
	return result;
}

- (void)setStopped:(BOOL)flag
{
	@synchronized(self) {
		mStopped = flag;
	}
}

//---------------------------------------------------------- 
//  delegate 
//---------------------------------------------------------- 
- (id<NTSampleModuleThreadDelegate>)delegate
{
    return mDelegate; 
}

- (void)setDelegate:(id<NTSampleModuleThreadDelegate>)theDelegate
{
    if (mDelegate != theDelegate)
        mDelegate = theDelegate;
}

- (void)threadDoneOnMainThread:(NSArray*)result;
{
	if (![self stopped])
		[[self delegate] thread:self result:result];
}

@end

@implementation NTSampleModuleThread (Thread)

- (void)threadProc;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableArray* result = [NSMutableArray array];
	NSMutableDictionary* info;
	NSEnumerator *enumerator = [[self selection] objectEnumerator];
	id<NTFSItem> item;
	
	while (item = [enumerator nextObject])
	{
		info = [NSMutableDictionary dictionary];
		
		[info setObject:[item displayName] forKey:@"name"];
		[info setObject:[item permissionString] forKey:@"permissions"];
		[info setObject:[[item modificationDate] description] forKey:@"modified"];
		[info setObject:[item kindString] forKey:@"kind"];
		
		[result addObject:info];
		
		if ([self stopped])
			break;
	}
	
	if (![self stopped])
		[self performSelectorOnMainThread:@selector(threadDoneOnMainThread:) withObject:[NSArray arrayWithArray:result] waitUntilDone:NO];
	
	[pool release];
}

@end



