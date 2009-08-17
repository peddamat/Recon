//
//  NSDocument-NTExtensions.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/13/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NSDocument-NTExtensions.h"

@implementation NSDocument (NTExtensions)

- (NTFileDesc*)fileDesc;
{
	NTFileDesc* desc = nil;
	
	if ([self fileURL])
		desc = [NTFileDesc descNoResolve:[[self fileURL] path]];
	
	return desc;
}

@end
