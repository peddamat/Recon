//
//  NTITunesXMLFile.h
//  iLike
//
//  Created by Steve Gehrman on 12/10/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTITunesXMLFile;

@protocol NTITunesXMLFileDelegateProtocol <NSObject>
- (void)iTunesXMLFile_wasUpdated:(NTITunesXMLFile*)file;
@end

@interface NTITunesXMLFile : NSObject
{
	id<NTITunesXMLFileDelegateProtocol> delegate;
	
	NSString* mDatabasePath; 
	
	int mKQueueFD;  // kqueue event fd
	
	NSPipe* mPipe;
	int mFD;  // iTunes folder we are watching
	NSDate* mModificationDate;
	
	BOOL mSentFolderModifiedNotification;
}

@property (assign) id<NTITunesXMLFileDelegateProtocol> delegate;  // not retained

+ (NTITunesXMLFile*)file:(id<NTITunesXMLFileDelegateProtocol>)theDelegate;
- (void)clearDelegate;

- (NSString *)databasePath;

// kill running thread, no longer valid 
- (void)kill;

@end

