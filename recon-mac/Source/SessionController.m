//
//  ScanController.m
//  Recon
//
//  Created by Sumanth Peddamatham on 7/1/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//

#import "SessionController.h"
#import "ArgumentListGenerator.h"
#import "NmapController.h"
#import "XMLController.h"
#import "PrefsController.h"

#import <Foundation/NSFileManager.h>

// Managed Objects
#import "Session.h"
#import "Profile.h"


@interface SessionController ()

//@property (readwrite, retain) Session *session; 
@property (readwrite, retain) NSString *sessionUUID;   
@property (readwrite, retain) NSString *sessionDirectory;
@property (readwrite, retain) NSString *sessionOutputFile;   

@property (readwrite, assign) BOOL hasRun;   
@property (readwrite, assign) BOOL isRunning;
@property (readwrite, assign) BOOL deleteAfterAbort;

@property (readwrite, retain) NSArray *nmapArguments;   
@property (readwrite, assign) NmapController *nmapController;

@property (readwrite, retain) NSTimer *resultsTimer;
@property (readwrite, retain) XMLController *xmlController;

@end


@implementation SessionController

@synthesize session;
@synthesize sessionUUID;
@synthesize sessionDirectory;
@synthesize sessionOutputFile;

@synthesize hasRun;
@synthesize isRunning;
@synthesize deleteAfterAbort;

@synthesize nmapArguments;
@synthesize nmapController;

@synthesize resultsTimer;
@synthesize xmlController;

- (id)init
{
   if (![super init])
      return nil;
   
   // Generate a unique identifier for this controller
   self.sessionUUID = [SessionController stringWithUUID];
      
   self.hasRun = FALSE;
   self.isRunning = FALSE;
   self.deleteAfterAbort = FALSE;   
   
   self.xmlController = [[XMLController alloc] init];
   return self;
}

- (void)dealloc
{
   NSLog(@"");
   NSLog(@"SessionController: deallocating");      
   
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc removeObserver:self];
   
   [session release];
   [sessionUUID release];   
   [sessionDirectory release];   
   [sessionOutputFile release];
   
   [nmapArguments release];   
   [nmapController release];
   
   NSLog(@"Retain count %d", [nmapController retainCount]);
   
   [xmlController release];
   [resultsTimer invalidate];   
   [resultsTimer release];
   [super dealloc];
}

// -------------------------------------------------------------------------------
//	initWithProfile
// -------------------------------------------------------------------------------
- (void)initWithProfile:(Profile *)profile                           
            withTarget:(NSString *)sessionTarget               
inManagedObjectContext:(NSManagedObjectContext *)context
{
   NSLog(@"SessionController: initWithProfile!");
      
   // Make a copy of the selected profile
   Profile *profileCopy = [[self copyProfile:profile] autorelease];
   
   // Create new session in managedObjectContext
   session = [NSEntityDescription insertNewObjectForEntityForName:@"Session" 
                                                    inManagedObjectContext:context];
   
   [session setTarget:sessionTarget];     // Store session target
   [session setDate:[NSDate date]];       // Store session start date
   [session setUUID:[self sessionUUID]];  // Store session UUID
   [session setStatus:@"Queued"];         // Store session status
   session.profile = profileCopy;         // Store session profile
      
   // Check PrefsController for user-specified sessions directory
//   NSString *nmapBinary = [PrefsController nmapBinary]       
   
   [self createSessionDirectory:sessionUUID];
         
   ArgumentListGenerator *a = [[ArgumentListGenerator alloc] init];
   // Convert selected profile to nmap arguments
   self.nmapArguments = [a convertProfileToArgs:profile withTarget:sessionTarget withOutputFile:sessionOutputFile];   
   
   [self initNmapController];
   
}

// -------------------------------------------------------------------------------
//	initWithSession: 
// -------------------------------------------------------------------------------
- (void)initWithSession:(Session *)s
{
   Profile *profile = [s profile];

   self.session = s;
   self.sessionUUID = [s UUID];

   [self createSessionDirectory:[s UUID]];

   ArgumentListGenerator *a = [[ArgumentListGenerator alloc] init];
   // Convert selected profile to nmap arguments
   self.nmapArguments = [a convertProfileToArgs:profile withTarget:[s target] withOutputFile:sessionOutputFile];   
   
   [self initNmapController];   
}

// -------------------------------------------------------------------------------
//	copyProfile: Return a copy of the profile
// -------------------------------------------------------------------------------
- (Profile *)copyProfile:(Profile *)profile
{
   NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];   
   NSEntityDescription *entity = [NSEntityDescription entityForName:@"Profile"    
                                             inManagedObjectContext:[profile managedObjectContext]];
   [request setEntity:entity];

   NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", @"Saved Sessions"];   
   [request setPredicate:predicate];

   NSError *error = nil;   
   NSArray *array = [[profile managedObjectContext] executeFetchRequest:request error:&error];   
   
   // Saved Sessions Folder
   Profile *savedSessions = [array lastObject];
   
   // Make a copy of the selected profile
   Profile *profileCopy = [[NSEntityDescription insertNewObjectForEntityForName:@"Profile" 
                                                         inManagedObjectContext:[profile managedObjectContext]] retain];
   NSDictionary *values = [profile dictionaryWithValuesForKeys:[[profileCopy entity] attributeKeys]];      
   [profileCopy setValuesForKeysWithDictionary:values];      
   [profileCopy setName:[NSString stringWithFormat:@"Copy of %@",[profile name]]];
   [profileCopy setIsEnabled:NO];   
   [profileCopy setParent:savedSessions];
   
   return profileCopy;
}

// -------------------------------------------------------------------------------
//	createSessionDirectory: 
// -------------------------------------------------------------------------------
- (BOOL)createSessionDirectory:(NSString *)uuid
{
   PrefsController *prefs = [PrefsController sharedPrefsController];
   
   // Create directory for new session   
   NSFileManager *NSFm = [NSFileManager defaultManager];
//   NSString *dirName = [PrefsController applicationSessionsFolder];   
   NSString *dirName = [prefs sessionDirectory];      
   self.sessionDirectory = [dirName stringByAppendingPathComponent:uuid];
   self.sessionOutputFile = [sessionDirectory stringByAppendingPathComponent:@"nmap-output.xml"];
   
   if ([NSFm createDirectoryAtPath:sessionDirectory attributes: nil] == NO) {
      NSLog (@"Couldn't create directory!\n");
      // TODO: Notify SessionManager of file creation error
      return NO;
   }
   
   return YES;
}

// -------------------------------------------------------------------------------
//	initNmapController
// -------------------------------------------------------------------------------
- (void)initNmapController
{
   PrefsController *prefs = [PrefsController sharedPrefsController];
   
   // Call NmapController with outputFile and argument list   
   self.nmapController = [[NmapController alloc] initWithNmapBinary:[prefs nmapBinary]                                                   
                                                           withArgs:nmapArguments 
                                                 withOutputFilePath:sessionDirectory];   
   
   // Register to receive notifications from NmapController
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc addObserver:self
          selector:@selector(successfulRunNotification:)
              name:@"NCsuccessfulRun"
            object:nmapController];
   [nc addObserver:self
          selector:@selector(abortedRunNotification:)
              name:@"NCabortedRun"
            object:nmapController];
   [nc addObserver:self
          selector:@selector(unsuccessfulRunNotification:)
              name:@"NCunsuccessfulRun"
            object:nmapController];
   
   NSLog(@"SessionController: Registered with notification center");      
}

// -------------------------------------------------------------------------------
//	startScan
// -------------------------------------------------------------------------------
- (void)startScan
{      
   // Reinitialize controller if previously run/aborted
   if ([nmapController hasRun])
      [self initNmapController];
   
   self.hasRun = TRUE;   
   self.isRunning = TRUE;
   [session setStatus:@"Running"];
   
   // Setup a timer to read the progress
   resultsTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5
                                             target:self
                                           selector:@selector(checkProgress:)
                                           userInfo:nil
                                            repeats:YES] retain];   
   
   [nmapController startScan];
}

// -------------------------------------------------------------------------------
//	checkProgress: Called by the resultsTimer
// -------------------------------------------------------------------------------
- (void)checkProgress:(NSTimer *)aTimer
{
   // Call XMLController with session directory and managedObjectContext
   [xmlController parseXMLFile:sessionOutputFile inSession:session onlyReadProgress:TRUE];      
   
//   NSLog(@"SessionController: Percent: %@", [session progress]);
}


// -------------------------------------------------------------------------------
//	abortScan
// -------------------------------------------------------------------------------
- (void)abortScan
{
   self.hasRun = TRUE;
   [nmapController abortScan];  
}

// -------------------------------------------------------------------------------
//	deleteSession: Remove the current session from Core Data.  Works even if the
//                session is currently running.
// -------------------------------------------------------------------------------
- (void)deleteSession
{
   self.hasRun = TRUE;
   self.deleteAfterAbort = TRUE;   
   [nmapController abortScan];
}

// -------------------------------------------------------------------------------
//	successfulRunNotification: NmapController notifies us that the NTask has completed.
// -------------------------------------------------------------------------------
- (void)successfulRunNotification: (NSNotification *)notification
{
   // Invalidate the progess timer
   [resultsTimer invalidate];
   
   // Call XMLController with session directory and managedObjectContext
   [xmlController parseXMLFile:sessionOutputFile inSession:session onlyReadProgress:FALSE];      
    
   self.isRunning = FALSE;
   [session setStatus:@"Done"];
   [session setProgress:[NSNumber numberWithFloat:100]];   
   
   // Send notification to SessionManager that session is complete
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc postNotificationName:@"SCsuccessfulRun" object:self];
}

// -------------------------------------------------------------------------------
//	abortedRunNotification: 
// -------------------------------------------------------------------------------
- (void)abortedRunNotification: (NSNotification *)notification
{
   // Invalidate the progess timer
   [resultsTimer invalidate];   
   
   self.isRunning = FALSE;
   [session setStatus:@"Aborted"];
   [session setProgress:[NSNumber numberWithFloat:0]];
      
   if (deleteAfterAbort == TRUE)
   {            
      NSManagedObjectContext *context = [session managedObjectContext];
      [context deleteObject:session];
   }   
   
   // Send notification to SessionManager that session is complete
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc postNotificationName:@"SCabortedRun" object:self];         
}

// -------------------------------------------------------------------------------
//	unsuccessfulRunNotification: 
// -------------------------------------------------------------------------------
- (void)unsuccessfulRunNotification:(NSNotification *)notification
{
   // Invalidate the progess timer
   [resultsTimer invalidate];   
   
   self.isRunning = FALSE;
   [session setStatus:@"Error"];   
   [session setProgress:[NSNumber numberWithFloat:0]];   
   
   // Send notification to SessionManager that session is complete
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc postNotificationName:@"SCunsuccessfulRun" object:self];   
}   

// -------------------------------------------------------------------------------
//	stringWithUUID
// -------------------------------------------------------------------------------
+ (NSString *)stringWithUUID 
{
   CFUUIDRef uuidObj = CFUUIDCreate(nil);
   NSString *uuidString = (NSString*)CFUUIDCreateString(nil, uuidObj);
   CFRelease(uuidObj);
   return [uuidString autorelease];
}

@end
