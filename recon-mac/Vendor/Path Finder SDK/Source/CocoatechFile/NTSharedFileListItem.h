//
//  NTSharedFileListItem.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 4/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTVolumeMgrState;

@interface NTSharedFileListItem : NSObject 
{
	LSSharedFileListItemRef itemRef;
	NSString* name;
	NSNumber* uniqueID;
	
	id cachedURL;
	id cachedResolvedURL;
	NTVolumeMgrState* volumeMgrState;
	UInt64 networkStateID;
}

@property (assign) LSSharedFileListItemRef itemRef;
@property (retain) NSString* name;
@property (retain) NSNumber* uniqueID;
@property (assign) UInt64 networkStateID;

+ (NTSharedFileListItem*)item:(LSSharedFileListItemRef)theItem;

// mounts shared volume if a server, returns URL
- (NSURL*)resolvedURL;
- (NSURL*)url;  // returns nil if not resolvable without UI

- (NSImage*)iconWithSize:(int)theSize;
@end
