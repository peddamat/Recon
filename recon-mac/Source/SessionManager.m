//
//  SessionManager.m
//  recon
//
//  Created by Sumanth Peddamatham on 7/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SessionManager.h"
#import "SessionController.h"

@implementation SessionManager

- (id)init
{
   if ((self = [super init])) {   
      runningSessionDictionary = [[NSMutableDictionary alloc] init];   
      runningSessionCount = 0;
      processingQueue = FALSE;
      
      // Register to receive notifications from SessionController
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
      [nc addObserver:self
             selector:@selector(sessionTerminated:)
                 name:@"sessionTerminated"
               object:nil];
      NSLog(@"SessionManager: Registered with notification center");   
   }
   
   return self;
}

- (void)queueSessionWithProfile:(Profile *)profile andTarget:(NSString *)target
{
   SessionController *newSession = [[[SessionController alloc] init] autorelease];
   
   // Initiate a new session
   [newSession initWithProfile:profile 
                    withTarget:target 
        inManagedObjectContext:[profile managedObjectContext]];      
   
   [runningSessionDictionary setObject:newSession forKey:[newSession sessionUUID]];   
}

- (void)removeSession:(NSString *)sessionUUID
{
   NSLog(@"SessionManager: Removing session: %@", sessionUUID); 
   
   // TODO: Check session status before removing.  If running, stop first
   [runningSessionDictionary removeObjectForKey:sessionUUID];  
   runningSessionCount--;
   
   if ([runningSessionDictionary count] == 0) {
      processingQueue = FALSE;
      NSLog(@"SessionManager: No more sessions!");
   }
}

- (void)launchSession:(Session *)session
{
   // TODO: Actually launch session
   runningSessionCount++;
}

- (void)launchNextSession
{
   id dictKey;
   NSArray *allKeys = [runningSessionDictionary allKeys];   
   NSEnumerator *e = [allKeys objectEnumerator];
   
   SessionController *sc = nil; 
   
   while (dictKey = [e nextObject])
   {
      sc = [runningSessionDictionary valueForKey:dictKey];
      
      if([sc isRunning] == FALSE)
      {
         [sc startScan];
         runningSessionCount++;
         return;
      }
   }
}

- (void)processQueue
{
   if (!processingQueue)
   {
      [self launchNextSession];
      processingQueue = TRUE;
   }
}

- (void)sessionTerminated: (NSNotification *)notification
{   
   SessionController *completedSession = [notification object];
   NSString *sessionUUID = [completedSession sessionUUID];
   
   runningSessionCount--;
   
   [self removeSession:sessionUUID];

   NSLog(@"SessionManager: Completed and removed: %@", [completedSession sessionUUID]);
   
   if (processingQueue)
      [self launchNextSession];
   
}

- (void)dealloc
{
   [[NSNotificationCenter defaultCenter] removeObserver:self];   
   [runningSessionDictionary dealloc];
   [super dealloc];
}

@end
