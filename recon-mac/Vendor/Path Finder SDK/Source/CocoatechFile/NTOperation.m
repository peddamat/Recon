//
//  NTOperation.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTOperation.h"

@implementation NTOperation

@synthesize delegate;
@synthesize parameter;
@synthesize result;

+ (NTOperation*)operation:(NSObject<NTOperationDelegateProtocol>*)theDelegate
				parameter:(id)theParameter;
{
	NTOperation* result = [[[self class] alloc] init];
	
	result.delegate = theDelegate;
	result.parameter = theParameter;
	
	return [result autorelease];
}

- (void)dealloc;
{
	if (self.delegate)
		[NSException raise:@"must call clearDelegate" format:@"%@", NSStringFromClass([self class])];

	self.parameter = nil;
	self.result = nil;
	
	[super dealloc];
}

- (void)operationDone;
{
	// always call even if canceled
	[[self delegate] performSelectorOnMainThread:@selector(operation_complete:) withObject:self waitUntilDone:NO];
}
	 
- (void)clearDelegate;
{
	self.delegate = nil;
}

@end
