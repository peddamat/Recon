//
//  NTSVNDisplayMgr.h
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 1/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTSVNStatusResult, NTSVNTextResult, NTSVNDisplayMgr;

typedef enum NTSVNDisplayMode 
{
	kSVNDisplayMode_none,
	kSVNDisplayMode_status,
	kSVNDisplayMode_text,
	kSVNDisplayMode_error,
	kSVNDisplayMode_toolLog,
	kSVNDisplayMode_progress
	
} NTSVNDisplayMode;

@protocol NTSVNDisplayMgrDelegate <NSObject>
- (void)displayMgr_refreshHTML:(NTSVNDisplayMgr*)mgr;
- (void)displayMgr_restoreScrollPositionOnReload:(NTSVNDisplayMgr*)mgr;
@end

@interface NTSVNDisplayMgr : NSObject 
{
	id<NTSVNDisplayMgrDelegate> mDelegate;
	 
	NTSVNDisplayMode mMode;
	
	// results
	NTSVNStatusResult *mStatusResult;
	NTSVNTextResult* mTextResult;
	
	// html we cached
	NSString* mProgressHTML;
	NSString* mErrorHTML;
	NSString* mToolLogHTML;	
	NSString *mDelayedProgressString;
	
	// url to our animated progress image
	NSURL* mProgressBarURL;
	
	// complete log of commands and results
	NSMutableString* mToolLog;	
}

+ (NTSVNDisplayMgr*)displayMgr;

- (id<NTSVNDisplayMgrDelegate>)delegate;
- (void)setDelegate:(id<NTSVNDisplayMgrDelegate>)theDelegate;

// this is what gets displayed to user
- (NSString*)displayString;

// called when directory changes
- (void)invalidate;

	// called to update
- (void)updateWithToolResult:(NSDictionary*)result;
- (void)updateProgress:(NSString*)progress;
- (void)updateMessage:(NSString*)message;

// append to log and put in log view mode
- (void)appendToToolLog:(NSString*)append;
- (void)showToolLog;

@end
