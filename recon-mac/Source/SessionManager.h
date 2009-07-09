//
//  SessionManager.h
//  recon
//
//  Created by Sumanth Peddamatham on 7/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Profile;
@class Session;

@interface SessionManager : NSObject
{
	NSMutableDictionary *runningSessionDictionary;
   int runningSessionCount;
   BOOL processingQueue;
}

- (void)queueSessionWithProfile:(Profile *)profile andTarget:(NSString *)target;
- (void)removeSession:(NSString *)sessionUUID;
- (void)launchSession:(Session *)session;
- (void)processQueue;

@end;


