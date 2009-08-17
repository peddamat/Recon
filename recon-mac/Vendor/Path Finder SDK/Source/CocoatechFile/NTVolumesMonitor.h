//
//  NTVolumesMonitor.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTFSMonitor.h"

@class NTFolderWatcher;

@interface NTVolumesMonitor : NTFSMonitor
{
	NTFolderWatcher* watcher;
}

@property (retain) NTFolderWatcher* watcher;
@end
