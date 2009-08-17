//
//  SessionManager.h
//  Recon
//
//  Created by Sumanth Peddamatham on 7/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Profile;
@class Session;
@class SessionController;

@interface SessionManager : NSObject {
   
   BOOL processingQueue;
   
	NSMutableDictionary *sessionControllerQueue;   
   NSArrayController *sessionsArrayController;
}

+ (SessionManager *)sharedSessionManager;
@property (readwrite, retain)NSArrayController *sessionsArrayController;

- (Session *)queueSessionWithProfile:(Profile *)profile withTarget:(NSString *)sessionTarget;
- (Session *)queueExistingSession:(Session *)session withGrowl:(BOOL)notify;
- (void)queueExistingSessions:(NSArray *)sessions;

- (void)deleteSession:(Session *)session;
- (void)abortSession:(Session *)session;
- (void)launchSession:(Session *)session;
- (void)launchNextSession;
- (void)updateQueueFlag;
- (void)processQueue;

- (void)registerNotificationsFromSessionController:(SessionController *)sc;

@end


