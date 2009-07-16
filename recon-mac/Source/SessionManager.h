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
@class SessionController;

@interface SessionManager : NSObject
{
	NSMutableDictionary *sessionControllers;   
   BOOL processingQueue;
}

- (void)queueSessionWithProfile:(Profile *)profile withTarget:(NSString *)target;
- (void)queueExistingSession:(Session *)session;

- (void)deleteSession:(Session *)session;
- (void)abortSession:(Session *)session;
- (void)launchSession:(Session *)session;
- (void)launchNextSession;
- (void)updateQueueFlag;
- (void)processQueue;

- (void)registerNotificationsFromSessionController:(SessionController *)sc;

@end


