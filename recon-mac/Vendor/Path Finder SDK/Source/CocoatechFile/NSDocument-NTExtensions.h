//
//  NSDocument-NTExtensions.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/13/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFileDesc;

@interface NSDocument (NTExtensions)

- (NTFileDesc*)fileDesc;

@end
