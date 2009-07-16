//
//  SessionManager.m
//  recon
//
//  Created by Sumanth Peddamatham on 7/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SessionManager.h"
#import "SessionController.h"
#import "SPGrowlController.h"

#import "Session.h"

@interface SessionManager ()

@property (readwrite, retain) NSMutableDictionary *sessionControllers;   
@property (readwrite, assign) BOOL processingQueue;

@end

@implementation SessionManager

@synthesize sessionControllers;
@synthesize processingQueue;

// -------------------------------------------------------------------------------
//	init
// -------------------------------------------------------------------------------
- (id)init
{
   if ((self = [super init])) {   
      self.sessionControllers = [[NSMutableDictionary alloc] init];       
      self.processingQueue = FALSE;
   }
   
   return self;
}

// -------------------------------------------------------------------------------
//	queueSessionWithProfile: The Session Manager allocates a new Session Controller
//            and adds it to a dictionary for queuing.  This allows removal of 
//            queued Session Controllers by session UUID.
// -------------------------------------------------------------------------------
- (void)queueSessionWithProfile:(Profile *)profile withTarget:(NSString *)target
{
   SessionController *newSessionController = [[[SessionController alloc] init] autorelease];
   
   // Initiate a new session
   [newSessionController initWithProfile:profile 
                              withTarget:target 
                  inManagedObjectContext:[profile managedObjectContext]];     
   
   // Register to receive notifications from the new Session Controller
   [self registerNotificationsFromSessionController:newSessionController];

   // Store a reference to the Session Controller
   [sessionControllers setObject:newSessionController 
                          forKey:[newSessionController sessionUUID]];   
   
   // Fire off a Growl notification
	[[SPGrowlController sharedGrowlController] 
    notifyWithTitle:@"Queued Nmap Session" 
    description:[NSString stringWithFormat: @"On target: %@", target] 
    notificationName:@"Connected"];      
}

// -------------------------------------------------------------------------------
//	queueExistingSession: 
// -------------------------------------------------------------------------------
- (void)queueExistingSession:(Session *)session
{
 
   SessionController *newSessionController = [[[SessionController alloc] init] autorelease];
 
   // Initiate a new session
   [newSessionController initWithSession:session];
   
   // Register to receive notifications from the new Session Controller
   [self registerNotificationsFromSessionController:newSessionController];
   
   // Store a reference to the Session Controller
   [sessionControllers setObject:newSessionController      
                          forKey:[newSessionController sessionUUID]];   
   
   // Fire off a Growl notification
	[[SPGrowlController sharedGrowlController] 
    notifyWithTitle:@"Queued Nmap Session" 
    description:@""
    notificationName:@"Connected"];      
   
}

// -------------------------------------------------------------------------------
//	deleteSession: Completely delete a session from the Core Data store
// -------------------------------------------------------------------------------
- (void)deleteSession:(Session *)session
{
   NSString *sessionUUID = [session UUID];
   
   // If a Session Controller exists for this session...
   if ([sessionControllers valueForKey:sessionUUID] != nil) {
      
      [[sessionControllers valueForKey:sessionUUID] deleteSession]; 
      [sessionControllers removeObjectForKey:sessionUUID];
      [self updateQueueFlag];      
   }
   // ... otherwise, remove it manually
   else {
      
      NSManagedObjectContext *context = [[session managedObjectContext] autorelease];
      [context deleteObject:session];
   }
   
   NSLog(@"SessionManager: Removing session: %@", sessionUUID);    
   
   // Fire off a Growl notification
	[[SPGrowlController sharedGrowlController] 
    notifyWithTitle:@""
    description:@""
    notificationName:@"Connected"];         
   
}

// -------------------------------------------------------------------------------
//	abortSession:
// -------------------------------------------------------------------------------
- (void)abortSession:(Session *)session
{
   NSString *sessionUUID = [session UUID];

   // If a Session Controller exists for this session...
   if ([sessionControllers valueForKey:sessionUUID] != nil) {

      [[sessionControllers valueForKey:sessionUUID] abortScan]; 
      
   }
   // ... otherwise, just update the Session status manually
   else {
      
      [session setStatus:@"Aborted"];
   }      
      
   NSLog(@"SessionManager: Aborting session: %@", sessionUUID);    
}

// -------------------------------------------------------------------------------
//	launchSession: 
// -------------------------------------------------------------------------------
- (void)launchSession:(Session *)session
{
   NSString *sessionUUID = [session UUID];
   NSLog(@"SessionManager: launchSession");
   // Grab a reference to the Session Controller
   SessionController *sc = [sessionControllers valueForKey:sessionUUID];
   
   // If a Session Controller exists for this session...
   if (sc != nil)
   {
      if ([sc isRunning] == FALSE)
      {
         // Growl notifier
         [[SPGrowlController sharedGrowlController] notifyWithTitle:@"Starting Nmap Session" description:@"" notificationName:@"Connected"];            
         [sc startScan];
      }
   }
   // ... otherwise, create a session controller and launch it
   else
   {
      [self queueExistingSession:session];
      [self launchSession:session];
   }
}

// -------------------------------------------------------------------------------
//	launchNextSession
// -------------------------------------------------------------------------------
- (void)launchNextSession
{
   id dictKey;
   NSEnumerator *e = [[sessionControllers allKeys] objectEnumerator];
   SessionController *sc = nil; 
   
   while (dictKey = [e nextObject]) 
   {      
      sc = [sessionControllers valueForKey:dictKey];
      
      // If the session isn't running, start it
      if([sc isRunning] == FALSE) {
    //     [self launchSession:dictKey];
         [sc startScan];
         return;
      }
   }
}

// -------------------------------------------------------------------------------
//	processQueue: Start processing the stored Session Controllers
// -------------------------------------------------------------------------------
- (void)processQueue
{   
   if ([sessionControllers count] > 0)
   {
      self.processingQueue = TRUE;      
      [self launchNextSession];
   }
   else
      NSLog(@"SessionManager: Queue empty!");
}

// -------------------------------------------------------------------------------
//	updateQueueFlag: 
// -------------------------------------------------------------------------------
- (void)updateQueueFlag
{
   if ([sessionControllers count] == 0) 
   {
      self.processingQueue = FALSE;
      NSLog(@"SessionManager: No more sessions!");
      
      // Fire off a Growl notification
      [[SPGrowlController sharedGrowlController] notifyWithTitle:@"Done processing queued sessions" description:@"" notificationName:@"Connected"];            
   }      
}

// -------------------------------------------------------------------------------
//	registerNotificationsFromSessionController: Session Controllers notify the Session Manager upon completion.
// -------------------------------------------------------------------------------
- (void)registerNotificationsFromSessionController:(SessionController *)sc
{
   // Register to receive notifications from the new SessionController
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc addObserver:self
          selector:@selector(successfulRunNotification:)
              name:@"SCsuccessfulRun"
            object:sc];
   [nc addObserver:self
          selector:@selector(abortedRunNotification:)
              name:@"SCabortedRun"
            object:sc];
   [nc addObserver:self
          selector:@selector(unsuccessfulRunNotification:)
              name:@"SCunsuccessfulRun"
            object:sc];   
   
   NSLog(@"SessionManager: Registered with notification center");        
}

// -------------------------------------------------------------------------------
//	successfulRunNotification: Session Controllers notify the Session Manager upon completion.
// -------------------------------------------------------------------------------
- (void)successfulRunNotification: (NSNotification *)notification
{   
   NSString *sessionUUID = [[notification object] sessionUUID];
   
   [sessionControllers removeObjectForKey:sessionUUID];
   [self updateQueueFlag];
   
	[[SPGrowlController sharedGrowlController] notifyWithTitle:@"Session complete" description:@"" notificationName:@"Connected"];      
   NSLog(@"SessionManager: Completed: %@\n\n", sessionUUID);
   
   if (processingQueue)
      [self launchNextSession];
}

// -------------------------------------------------------------------------------
//	abortedRunNotification: 
// -------------------------------------------------------------------------------
- (void)abortedRunNotification: (NSNotification *)notification
{   
   NSString *sessionUUID = [[notification object] sessionUUID];
   
   [sessionControllers removeObjectForKey:sessionUUID];
   [self updateQueueFlag];
   
	[[SPGrowlController sharedGrowlController] notifyWithTitle:@"Session complete" description:@"" notificationName:@"Connected"];      
   NSLog(@"SessionManager: Aborted: %@\n\n", sessionUUID);
   
   if (processingQueue)
      [self launchNextSession];   
}

// -------------------------------------------------------------------------------
//	unsuccessfulRunNotification: 
// -------------------------------------------------------------------------------
- (void)unsuccessfulRunNotification: (NSNotification *)notification
{   
   NSString *sessionUUID = [[notification object] sessionUUID];
   
   [sessionControllers removeObjectForKey:sessionUUID];
   [self updateQueueFlag];
   
	[[SPGrowlController sharedGrowlController] notifyWithTitle:@"Session complete" description:@"" notificationName:@"Connected"];      
   NSLog(@"SessionManager: Unsuccessfully run: %@\n\n", sessionUUID);
   
   if (processingQueue)
      [self launchNextSession];
}

- (void)dealloc
{
   NSLog(@"");
   NSLog(@"SessionManager: deallocating");   
   [[NSNotificationCenter defaultCenter] removeObserver:self];   
   
   [sessionControllers dealloc];
   [super dealloc];
}

@end
