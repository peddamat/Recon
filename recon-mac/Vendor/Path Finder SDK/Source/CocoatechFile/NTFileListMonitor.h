//
//  NTFileListMonitor.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/9/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFileListMonitor, NTFSWatcher;

@protocol NTFileListMonitorDelegate <NSObject>
- (void)fileListMonitor_updated:(NTFileListMonitor*)monitor;
@end

@interface NTFileListMonitor : NSObject
{
	id<NTFileListMonitorDelegate> delegate;
	NSArray* descs;
	
	NTFSWatcher *mWatcher;
	NTThreadRunner *mThreadRunner;
}

@property (assign) id<NTFileListMonitorDelegate> delegate;  // not retained
@property (retain) NSArray* descs;

+ (NTFileListMonitor*)monitor:(NSArray*)descs delegate:(id<NTFileListMonitorDelegate>)delegate;
- (void)clearDelegate;

- (NTFileDesc*)desc;  // shortcut of the above, returns first item

@end
