//
//  NTFSEventMessage.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTFSEventMessage.h"
#import "NTFSSize.h"

@interface NTFSEventMessage (Private)
@end

@implementation NTFSEventMessage

@synthesize path;
@synthesize rescanSubdirectories;

+ (NTFSEventMessage*)message:(NSString*)thePath rescanSubdirectories:(BOOL)theRescanSubdirectories;
{
	NTFSEventMessage* result = [[NTFSEventMessage alloc] init];
	
	result.path = thePath;
	result.rescanSubdirectories = theRescanSubdirectories;
	
	return [result autorelease];
}

- (void)dealloc;
{	
	self.path = nil;
	
	[super dealloc];
}

- (void)updateMessage:(BOOL)theRescanSubdirectories
{
	if (!self.rescanSubdirectories && theRescanSubdirectories)
		self.rescanSubdirectories = YES;
}

@end

@implementation NTFSEventMessage (Private)

- (NSString*)description;
{
	return [NSString stringWithFormat:@"%@:%@", self.path, (self.rescanSubdirectories) ? @"YES":@"NO"];
}

@end

