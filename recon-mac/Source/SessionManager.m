//
//  SessionManager.m
//  Recon
//
//  Created by Sumanth Peddamatham on 7/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SessionManager.h"
#import "SessionController.h"
#import "SPGrowlController.h"

#import "Session.h"
#import "Profile.h"

@interface SessionManager ()

   @property (readwrite, retain) NSMutableDictionary *sessionControllerQueue;   
   @property (readwrite, assign) BOOL processingQueue;

@end

// -------------------------------------------------------------------------------
//	THIS CLASS IS A SINGLETON.  
// -------------------------------------------------------------------------------

@implementation SessionManager

   @synthesize sessionControllerQueue;
   @synthesize processingQueue;
   @synthesize sessionsArrayController;

static SessionManager *sharedSessionManager = nil;

// -------------------------------------------------------------------------------
//	init:
// -------------------------------------------------------------------------------
- (id)init
{
   if ((self = [super init])) {   
      self.sessionControllerQueue = [[NSMutableDictionary alloc] init];       
      self.processingQueue = FALSE;
   }
   
   return self;
}

- (void)dealloc
{
   [[NSNotificationCenter defaultCenter] removeObserver:self];   
   
   [sessionControllerQueue release];
   [super dealloc];
}

#pragma mark -
#pragma mark Queue handlers

// -------------------------------------------------------------------------------
//	queueSessionWithProfile: The Session Manager allocates a new Session Controller
//            and adds it to a dictionary for queuing.  This allows removal of 
//            queued Session Controllers by session UUID.
// -------------------------------------------------------------------------------
- (Session *)queueSessionWithProfile:(Profile *)profile withTarget:(NSString *)sessionTarget
{ 
   // Touch profile to allow sorting Profiles popup
   [profile setLastAccessDate:[NSDate date]];   
   
   SessionController *newSessionController = [[SessionController alloc] init];

   // Initiate a new session
   Session *newSession =
   [newSessionController initWithProfile:profile 
                              withTarget:sessionTarget 
                  inManagedObjectContext:[profile managedObjectContext]];
      
   // Register to receive notifications from the new Session Controller
   [self registerNotificationsFromSessionController:newSessionController];

   // Store a reference to the Session Controller
   [sessionControllerQueue setObject:newSessionController 
                          forKey:[newSessionController sessionUUID]];  
      
   // Fire off a Growl notification
	[[SPGrowlController sharedGrowlController] 
    notifyWithTitle:@"Queued Nmap Session" 
    description:[NSString stringWithFormat: @"Target: %@", sessionTarget] 
    notificationName:@"Connected"];  
   
   [newSessionController release];
   
   return newSession;
}

// -------------------------------------------------------------------------------
//	queueExistingSession: When the application is loaded from the persistent store,
//                       Sessions exist that haven't passed through the new Session
//                       Manager.
// -------------------------------------------------------------------------------
- (Session *)queueExistingSession:(Session *)session withGrowl:(BOOL)notify
{
   SessionController *newSessionController = [[SessionController alloc] init];
    
   // Initiate a new session
   Session *newSession =   
   [newSessionController initWithSession:session];

   // Register to receive notifications from the new Session Controller
   [self registerNotificationsFromSessionController:newSessionController];
   
   // Store a reference to the Session Controller
   [sessionControllerQueue setObject:newSessionController      
                          forKey:[newSessionController sessionUUID]];   
   
   // Fire off a Growl notification
   if (notify == YES)
   {
      [[SPGrowlController sharedGrowlController] 
       notifyWithTitle:@"Queued Nmap Session" 
       description:[NSString stringWithFormat: @"Target: %@", [session target]] 
       notificationName:@"Connected"];      
   }   
   
  [newSessionController release];
   
   return newSession;
}

// -------------------------------------------------------------------------------
//	queueExistingSessions:
// -------------------------------------------------------------------------------
- (void)queueExistingSessions:(NSArray *)sessions
{
   for (Session *session in sessions)
   {
      [self queueExistingSession:session withGrowl:NO];
   }   
   
   [[SPGrowlController sharedGrowlController] 
    notifyWithTitle:@"Queued Nmap Sessions" 
    description:[NSString stringWithFormat: @"Total Sessions: %d", [sessions count]] 
    notificationName:@"Connected"];         
}

// -------------------------------------------------------------------------------
//	launchSession: 
// -------------------------------------------------------------------------------
- (void)launchSession:(Session *)session
{
   // Grab a reference to the session's Session Controller
   SessionController *sc = [sessionControllerQueue valueForKey:[session UUID]];
      
   // If a Session Controller exists for this session...
   if (sc != nil)
   {
      if ([sc isRunning] == FALSE)
      {
         // Growl notifier
         [[SPGrowlController sharedGrowlController] 
          notifyWithTitle:@"Starting Nmap Session" 
          description:[NSString stringWithFormat: @"Target: %@", [[sc session] target]] 
          notificationName:@"Connected"];    
         
         [sc startScan];
      }
   }
   // ... otherwise, create a session controller and launch it
   else
   {
      [self queueExistingSession:session withGrowl:YES];
      [self launchSession:session];
   }
}

// -------------------------------------------------------------------------------
//	launchNextSession:
// -------------------------------------------------------------------------------
- (void)launchNextSession
{
   SessionController *sc = nil; 
   
   for (NSString *dictKey in [sessionControllerQueue allKeys])
   {      
      sc = [sessionControllerQueue valueForKey:dictKey];
      
      // If the session isn't running, start it
      if([sc isRunning] == FALSE) 
      {
         // Growl notifier
         [[SPGrowlController sharedGrowlController] 
          notifyWithTitle:@"Starting Nmap Session" 
          description:[NSString stringWithFormat: @"Target: %@", [[sc session] target]] 
          notificationName:@"Connected"];                     
         
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
   if ([sessionControllerQueue count] > 0)
   {
      self.processingQueue = TRUE;      
      [self launchNextSession];
   }
   else
      //ANSLog(@"SessionManager: Queue empty!");
      ;
}

// -------------------------------------------------------------------------------
//	abortSession: Abort a session in the Session Drawer.  Queued or not.
// -------------------------------------------------------------------------------
- (void)abortSession:(Session *)session
{
   NSString *sessionUUID = [session UUID];
   
   // If a Session Controller exists for this session...
   if ([sessionControllerQueue valueForKey:sessionUUID] != nil) {
      
      [[sessionControllerQueue valueForKey:sessionUUID] abortScan]; 
      
   }
   // ... otherwise, just update the Session status manually
   else {
      
      [session setStatus:@"Aborted"];
   }      
   
   //ANSLog(@"SessionManager: Aborting session: %@", sessionUUID);    
}

// -------------------------------------------------------------------------------
//	deleteSession: Completely delete a session from the Core Data store
// -------------------------------------------------------------------------------
- (void)deleteSession:(Session *)session
{
   NSString *sessionUUID = [session UUID];
   
   // If a Session Controller exists for this session...
   if ([sessionControllerQueue valueForKey:sessionUUID] != nil) {
      
      [[sessionControllerQueue valueForKey:sessionUUID] deleteSession]; 
   }
   // ... otherwise, remove it manually
   else {
      
      NSManagedObjectContext *context = [session managedObjectContext];
      [context deleteObject:session];
   }
   
   //ANSLog(@"SessionManager: Removing session: %@", sessionUUID);    
   
   // Fire off a Growl notification
//	[[SPGrowlController sharedGrowlController] 
//    notifyWithTitle:@""
//    description:@""
//    notificationName:@"Connected"];         
}

// -------------------------------------------------------------------------------
//	updateQueueFlag: 
// -------------------------------------------------------------------------------
- (void)updateQueueFlag
{
   if ([sessionControllerQueue count] == 0) 
   {
      self.processingQueue = FALSE;
      //ANSLog(@"SessionManager: No more sessions!");
      
      // Fire off a Growl notification
      [[SPGrowlController sharedGrowlController] 
       notifyWithTitle:@"Done Processing Queue"
       description:@"" 
       notificationName:@"Connected"];            
   }      
}

#pragma mark -
#pragma mark Notification center handlers

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
   
   //ANSLog(@"SessionManager: Registered with notification center");        
}

// -------------------------------------------------------------------------------
//	successfulRunNotification: Session Controllers notify the Session Manager upon completion.
// -------------------------------------------------------------------------------
- (void)successfulRunNotification: (NSNotification *)notification
{   
   NSString *sessionUUID = [[notification object] sessionUUID];
   SessionController *sc = [sessionControllerQueue objectForKey:sessionUUID];
   
   Session *completedSelection = [sc session];
   [sessionsArrayController setSelectedObjects:[NSArray arrayWithObject:completedSelection]];   
   
	[[SPGrowlController sharedGrowlController] 
    notifyWithTitle:@"Session complete"                                                   
    description:[NSString stringWithFormat: @"Target: %@", [completedSelection target]]     
    notificationName:@"Connected"];     
   
   //ANSLog(@"SessionManager: Completed: %@\n\n", sessionUUID);   
   
   [sessionControllerQueue removeObjectForKey:sessionUUID];
   [self updateQueueFlag];
      
   if (processingQueue)
      [self launchNextSession];
}

// -------------------------------------------------------------------------------
//	abortedRunNotification: 
// -------------------------------------------------------------------------------
- (void)abortedRunNotification: (NSNotification *)notification
{   
   NSString *sessionUUID = [[notification object] sessionUUID];   
   SessionController *sc = [sessionControllerQueue objectForKey:sessionUUID];
   
   Session *completedSelection = [sc session];
   [sessionsArrayController setSelectedObjects:[NSArray arrayWithObject:completedSelection]];      
   
	[[SPGrowlController sharedGrowlController] 
    notifyWithTitle:@"Session aborted"                                                   
    description:[NSString stringWithFormat: @"Target: %@", [completedSelection target]]     
    notificationName:@"Connected"];    
   
   //ANSLog(@"SessionManager: Aborted run: %@\n\n", sessionUUID);
   
   [sessionControllerQueue removeObjectForKey:sessionUUID];
   [self updateQueueFlag];
      
   if (processingQueue)
      [self launchNextSession];   
}

// -------------------------------------------------------------------------------
//	unsuccessfulRunNotification: 
// -------------------------------------------------------------------------------
- (void)unsuccessfulRunNotification: (NSNotification *)notification
{   
   NSString *sessionUUID = [[notification object] sessionUUID];
   SessionController *sc = [sessionControllerQueue objectForKey:sessionUUID];
   
   Session *completedSelection = [sc session];
   [sessionsArrayController setSelectedObjects:[NSArray arrayWithObject:completedSelection]];      
   
	[[SPGrowlController sharedGrowlController] 
    notifyWithTitle:@"Session ended unsuccessfully"     
    description:[NSString stringWithFormat: @"Target: %@", [completedSelection target]]     
    notificationName:@"Connected"];            
   
   //ANSLog(@"SessionManager: Unsuccessfully run: %@\n\n", sessionUUID);
   
   [sessionControllerQueue removeObjectForKey:sessionUUID];
   [self updateQueueFlag];
   
   if (processingQueue)
      [self launchNextSession];
}

#pragma mark -
#pragma mark Singleton methods (DON'T TOUCH)

// -------------------------------------------------------------------------------
//	The following methods allow this class to be a Singleton.
//
//  They are adapted from:
//    http://developer.apple.com/documentation/Cocoa/Conceptual/CocoaFundamentals/CocoaObjects/CocoaObjects.html
// -------------------------------------------------------------------------------

+ (SessionManager *)sharedSessionManager
{
   @synchronized(self) {
      
      if (sharedSessionManager == nil) {         
         [[self alloc] init]; // assignment not done here         
      }      
   }
   
   return sharedSessionManager;   
}

+ (id)allocWithZone:(NSZone *)zone
{
   @synchronized(self) {
      if (sharedSessionManager == nil) {
         sharedSessionManager = [super allocWithZone:zone];
         return sharedSessionManager;  // assignment and return on first allocation
      }
   }
   return nil; //on subsequent allocation attempts return nil   
}

- (id)copyWithZone:(NSZone *)zone
{
   return self;   
}

- (id)retain
{
   
   return self;   
}

- (unsigned)retainCount
{   
   return UINT_MAX;  //denotes an object that cannot be released   
}

- (void)release
{
   //do nothing   
}

- (id)autorelease

{
   return self;
}
@end
