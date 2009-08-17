//
//  NTFileListMonitorThread.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/9/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTFileListMonitorThread.h"

@interface NTFileListMonitorThread (hidden)
- (void)setDescs:(NSArray *)theLeft;
- (void)setChanged:(BOOL)flag;
@end

@implementation NTFileListMonitorThread

@synthesize descs, descsRemoved, descsModified;

+ (NTThreadRunner*)thread:(NSArray*)theDescs
				 delegate:(id<NTThreadRunnerDelegateProtocol>)delegate;
{
    NTFileListMonitorThread* param = [[[NTFileListMonitorThread alloc] init] autorelease];
    
    [param setDescs:theDescs];
	
	return [NTThreadRunner thread:param
						 priority:.8
						 delegate:delegate];	
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setDescs:nil];
    [super dealloc];
}

@end

// ---------------------------------------------------------------------------------------

@implementation NTFileListMonitorThread (Thread)

- (BOOL)doThreadProc;
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[[self descs] count]];
	NSEnumerator* enumerator = [[self descs] objectEnumerator];
	NTFileDesc* desc;
	
	while (desc = [enumerator nextObject])
	{
		if ([[self helper] killed])
			return NO;
		
		if ([desc hasBeenModified])
		{
			self.descsModified = YES;
			
			desc = [desc newDesc];
			if (![desc stillExists])
			{
				self.descsRemoved = YES;
				desc = nil;
			}
		}
		
		if (desc)
			[result addObject:desc];
	}
	
	if (self.descsModified)
		[self setDescs:[NSArray arrayWithArray:result]];
	
	return ![[self helper] killed];
}

@end
