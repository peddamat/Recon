//
//  NetstatController.m
//  Recon
//
//  Created by Sumanth Peddamatham on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NetstatController.h"

#import "MyDocument.h"
#import "SessionController.h"
#import "SessionManager.h"

#import "Connection.h"
#import "Profile.h"
#import "Session.h"

#include <arpa/inet.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <errno.h>
#include <ifaddrs.h>
#include <stdio.h>


@implementation NetstatController

@synthesize connections;
@synthesize testy;

- (id)init 
{
   if (self = [super init])
   {
      connections = [[NSMutableArray alloc] init];             
   }
   
   return self;
}

- (void)dealloc
{
   [connections release];
   [timer invalidate];
   [timer release];
   [super dealloc];
}


- (IBAction)changeInspectorTask:(id)sender
{
   NSLog(@"NetstatController: changeInspectorTask: %d", [sender tag]);
   
   if ([[sender title] hasPrefix:@"See"])
   {
      [self refreshConnectionsList:self];
      [regularHostsScrollView setHidden:TRUE];
      [netstatHostsScrollView setHidden:FALSE];
   }
   else
   {
      [regularHostsScrollView setHidden:FALSE];
      [netstatHostsScrollView setHidden:TRUE];      
   }
   
   if ([[sender title] hasPrefix:@"Find computers"])
   {
      [self searchLocalNetwork:self];
   }
}

// -------------------------------------------------------------------------------
//	chooseTask: State-machine handler for first tab of Network Assistant
// -------------------------------------------------------------------------------
- (IBAction)chooseTask:(id)sender
{
   // Determine which button is selected
   int row = [mainSelector selectedRow];
   NSLog(@"Selected: %i", row);
   
   switch (row) {
      // Find computers on local network
      case 0:
         NSLog(@"CIDR: %d", [self cidrForInterface:@"en1"]);
         break;
      // Find Bonjour-compatible
      case 1:
         break;
      // See connected machines
      case 2:
         [self refreshConnectionsList:self];
//         [self autoRefreshConnections];
         break;
      // Check for services on machine
      case 3:
         break;
      // Check if a machine is online
      case 4:
         break;
      default:
         break;
   }
   
   [mainTabView selectTabViewItemAtIndex:row+1];
}

// -------------------------------------------------------------------------------
//	searchLocalNetwork: Wrapper-function for ping-scanning local subnet
// -------------------------------------------------------------------------------
- (IBAction)searchLocalNetwork:(id)sender
{
   // Grab the Session Manager object
   SessionManager *sessionManager = [SessionManager sharedSessionManager];

   // Create a session for the scan
   Session *session = [NSEntityDescription insertNewObjectForEntityForName:@"Session" 
                                                    inManagedObjectContext:[sessionManager context]];
   
   [session setUUID:@"generated"];
   [session setDate:[NSDate date]];
   [session setTarget:[NSString stringWithFormat:@"192.168.0.1/%d",[self cidrForInterface:@"en0"]]];

   // Create a profile and populate it for basic ping-scanning
   Profile *profile = [NSEntityDescription insertNewObjectForEntityForName:@"Profile" 
                                                    inManagedObjectContext:[sessionManager context]];
   
   [profile setFastScan:[NSNumber numberWithBool:TRUE]];
//   [profile setTraceRoute:[NSNumber numberWithBool:TRUE]];
//   [profile setEnableAggressive:[NSNumber numberWithBool:TRUE]];
   
   // Link the session to the profile
   [session setProfile:profile];

   // Queue and launch the session
   [sessionManager queueExistingSession:session];
//   [sessionManager launchSession:session];

   // The interface needs the new session to be selected
   [sessionsController setSelectedObjects:[NSArray arrayWithObject:session]];
}

- (IBAction)launchScan:(id)sender
{
   // Grab the Session Manager object
   SessionManager *sessionManager = [SessionManager sharedSessionManager];
   
   [sessionManager processQueue];   
}

- (NSPredicate *)testy
{
   NSLog(@"NetstatController: testy");
   if (testy == nil) {
      //testy = [NSPredicate predicateWithFormat: @"UUID == 'generate'"];   
      testy = nil;
   }
   return testy;
}

// -------------------------------------------------------------------------------
//	cidrForInterface: Gets the CIDR for the passed IP address 
//   TODO: Doing this the lazy way using ifconfig, fix this!!!
// -------------------------------------------------------------------------------
- (int)cidrForInterface:(NSString *)ifName {
   NSAssert(nil != ifName, @"Interface name cannot be nil");
   
   // Prepare a task object
   NSTask *task = [[NSTask alloc] init];
   [task setLaunchPath:@"/bin/tcsh"];     // For some reason, using /bin/sh screws up the debug console   
   [task setArguments:[NSArray arrayWithObjects: @"-c", @"ifconfig | grep netmask | grep 192 | awk '{print $4}'", nil]];
   
   // Create the pipe to read from
   NSPipe *outPipe = [[NSPipe alloc] init];
   [task setStandardOutput:outPipe];
   [outPipe release];
   
   // Start the process
   [task launch];
   
   // Read the output
   NSData *data = [[outPipe fileHandleForReading]
                   readDataToEndOfFile];
   
   // Make sure the task terminates normally
   [task waitUntilExit];
   [task release];

   // Convert to a string
   NSString *aString = [[NSString alloc] initWithData:data
                                             encoding:NSUTF8StringEncoding];

   
   // Convert hexadecimal to int
   int p;
   sscanf([aString cStringUsingEncoding:NSUTF8StringEncoding], "%x", &p);
   
   //return [NSString stringWithCString:cstring];
   return bitcount(p);
}

int bitcount (unsigned int n) 
{
   int count = 0;
   while (n) {
      count += n & 0x1u;
      n >>= 1;
   }
   return count;
}


// -------------------------------------------------------------------------------
//	setConnections: 
// -------------------------------------------------------------------------------
- (void)setConnections:(NSMutableArray *)a
{
   // This is an unusual setter method.  We are going to add a lot
   // of smarts to it in the next chapter.
   if (a == connections)
      return;
   
   [a retain];
   [connections release];
   connections = a;
}

// -------------------------------------------------------------------------------
//	refreshConnectionsList: 
// -------------------------------------------------------------------------------
- (IBAction)refreshConnectionsList:(id)sender
{      
   NSLog(@"NetstatController: refreshConnectionsList");
      
   selectedConnection = [[connectionsController selectedObjects] lastObject];
   
   // Clear array controller
   [[connectionsController content] removeAllObjects];
   
   // Prepare a task object
   NSTask *task = [[NSTask alloc] init];
   [task setLaunchPath:@"/bin/tcsh"];     // For some reason, using /bin/sh screws up the debug console   
   
   // Prepare the netstat munging line
   [task setArguments:[NSArray arrayWithObjects: @"-c", @"netstat -d -n -f inet | grep \"ESTABLISHED\" | grep -v 127 | awk '{print $4, $5, $6 }'", nil]];
   
   // Create the pipe to read from
   NSPipe *outPipe = [[NSPipe alloc] init];
   [task setStandardOutput:outPipe];
   [outPipe release];
   
   // Start the process
   [task launch];
   
   // Read the output
   NSData *data = [[outPipe fileHandleForReading]
                   readDataToEndOfFile];
   
   // Make sure the task terminates normally
   [task waitUntilExit];
//   int status = [task terminationStatus];
   [task release];
         
   // Convert to a string
   NSString *aString = [[NSString alloc] initWithData:data
                                             encoding:NSUTF8StringEncoding];
   
   NSArray *line = [aString componentsSeparatedByString:@"\n"];
   int lineLength = [line count] - 1;
   
   Connection *c = nil;
   NSMutableArray *a = [[NSMutableArray alloc] init];
   
   for (int i = 0; i < lineLength; i++)
   {
      // Perl, how I miss thee...
      NSArray *p = [[line objectAtIndex:i] componentsSeparatedByString:@" "];
      NSArray *local = [[p objectAtIndex:0] componentsSeparatedByString:@"."];
      NSArray *remote = [[p objectAtIndex:1] componentsSeparatedByString:@"."];
      
      NSString *localIP = [NSString stringWithFormat:@"%@.%@.%@.%@", 
                           [local objectAtIndex:0], 
                           [local objectAtIndex:1], 
                           [local objectAtIndex:2], 
                           [local objectAtIndex:3]];
      NSString *localPort = [local objectAtIndex:4];

      NSString *remoteIP = [NSString stringWithFormat:@"%@.%@.%@.%@", 
                           [remote objectAtIndex:0], 
                           [remote objectAtIndex:1], 
                           [remote objectAtIndex:2], 
                            [remote objectAtIndex:3]];
      NSString *remotePort = [remote objectAtIndex:4];
      
      
      NSString *status = [p objectAtIndex:2];

      c = [[Connection alloc] initWithLocalIP:localIP
                                 andLocalPort:localPort
                                  andRemoteIP:remoteIP
                                andRemotePort:remotePort
                                    andStatus:status];
      [a addObject:c];
   }
     
   [connectionsController addObjects:a];
   
   if (selectedConnection != nil)
      [connectionsController setSelectedObjects:[NSArray arrayWithObject:selectedConnection]];
   else
      [connectionsController setSelectionIndex:0];
   
   // Release the string
   [aString release];
      
}

- (void)autoRefreshConnections
{
   // Setup a timer to auto-refresh list
   timer = [[NSTimer scheduledTimerWithTimeInterval:1
                                             target:self
                                           selector:@selector(checkThem:)
                                           userInfo:nil
                                            repeats:YES] retain];
   
}

- (void)checkThem:(NSTimer *)aTimer
{
   [self refreshConnectionsList:self];
}

@end
