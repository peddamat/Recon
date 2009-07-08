//
//  ScanController.m
//  recon
//
//  Created by Sumanth Peddamatham on 7/1/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//

#import "SessionController.h"
#import "ArgumentListGenerator.h"
#import "NmapController.h"
#import "XMLController.h"
#import "PrefsController.h"
#import "SPGrowlController.h"

#import <Foundation/NSFileManager.h>

// Managed Objects
#import "Session.h"


@implementation SessionController

@synthesize sessionUUID;
@synthesize isRunning;

- (id)init
{
   if (![super init])
      return nil;
   
   // Generate a unique identifier for this controller
   sessionUUID = [[SessionController stringWithUUID] retain];
   
   isRunning = FALSE;
}

- (void) initWithProfile:(Profile *)profile                           
              withTarget:(NSString *)sessionTarget               
  inManagedObjectContext:(NSManagedObjectContext *)context
{
   NSLog(@"SessionController: initWithProfile!");
      
   // Create new session in managedObjectContext
   session = [NSEntityDescription insertNewObjectForEntityForName:@"Session" 
                                                    inManagedObjectContext:context];

   [session setTarget:sessionTarget];     // Store session target
   [session setDate:[NSDate date]];       // Store session start date
   [session setUUID:[self sessionUUID]];  // Store session UUID
   [session setStatus:@"Queued"];        // Store session status
   session.profile = profile;             // Store session profile
      
   // Check PrefsController for user-specified sessions directory
//   NSString *nmapBinary = [PrefsController nmapBinaryString]       
   
   // Create directory for new session   
   NSFileManager *NSFm = [NSFileManager defaultManager];
   NSString *dirName = [PrefsController applicationSessionsFolder];   
   NSString *sessionDir = [dirName stringByAppendingPathComponent:sessionUUID];
   outputFile = [sessionDir stringByAppendingPathComponent:@"nmap-output.xml"];
   
   if ([NSFm createDirectoryAtPath:sessionDir attributes: nil] == NO) {
      NSLog (@"Couldn't create directory!\n");
      // TODO: Notify SessionManager of file creation error
      return;
   }
   
   // Growl notifier: Session Started!
	[[SPGrowlController sharedGrowlController] notifyWithTitle:@"Queued Nmap Session" description:[NSString stringWithFormat: @"On target: %@", sessionTarget] notificationName:@"Connected"];   
      
   // Convert selected profile to nmap arguments
   NSArray *args = [ArgumentListGenerator convertProfileToArgs:profile withTarget:sessionTarget withOutputFile:outputFile];   
   
   // Call NmapController with outputFile and argument list
   if (nmapController) {
      NSLog(@"SessionController: nmapController already instantiated!");
      // TODO: Notify MyDocument that nmap was already called
      return;
   }
      
   nmapController = [[NmapController alloc] initWithNmapBinary:@"/usr/local/bin/nmap" 
                                                      withArgs:args 
                                            withOutputFilePath:sessionDir];   
   
   // Keep outputFile around until nmap finishes scan
   [outputFile retain];
   [session retain];
   [nmapController retain];
}

- (void)startScan
{
   // Register to receive notifications from NmapController
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc addObserver:self
          selector:@selector(terminatedNotification:)
              name:NSTaskDidTerminateNotification //@"terminatedNotification"
            object:nil];
   NSLog(@"SessionController: Registered with notification center");   
   
   [nmapController startScan];
}

- (void)abortScan
{
   [nmapController abortScan];
}

// Sets the taskComplete flag when a terminated notification is received.
- (void)terminatedNotification: (NSNotification *)notification
{

   // Call XMLController with session directory and managedObjectContext
   XMLController *xmlController = [[XMLController alloc] init];     
   [xmlController parseXMLFile:outputFile inSession:session onlyReadProgress:FALSE];      
   
   NSLog(@"SessionController: Output: %@", outputFile);   
	[[SPGrowlController sharedGrowlController] notifyWithTitle:@"Session complete" description:@"" notificationName:@"Connected"];   
   
   [session setStatus:@"Done"];
   [outputFile release];
   
   // TODO: Send notification to MyDocument that session is complete
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc postNotificationName:@"sessionTerminated" object:self];
      
   NSLog(@"SessionController: Back!");   
}


/** Returns a UUID string
 */
+ (NSString *) stringWithUUID 
{
   CFUUIDRef uuidObj = CFUUIDCreate(nil);
   NSString *uuidString = (NSString*)CFUUIDCreateString(nil, uuidObj);
   CFRelease(uuidObj);
   return [uuidString autorelease];
}

- (void)dealloc
{
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc removeObserver:self];
   [super dealloc];
}

@end
