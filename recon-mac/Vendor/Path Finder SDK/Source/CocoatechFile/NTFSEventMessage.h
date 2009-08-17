//
//  NTFSEventMessage.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTFSEventMessage : NSObject {
	NSString* path;	
	BOOL rescanSubdirectories;	
}
@property (retain) NSString* path;
@property (assign) BOOL rescanSubdirectories;

+ (NTFSEventMessage*)message:(NSString*)thePath rescanSubdirectories:(BOOL)theRescanSubdirectories;
- (void)updateMessage:(BOOL)theRescanSubdirectories;

@end
