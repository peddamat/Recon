//
//  InspectorController.m
//  Recon
//
//  Created by Sumanth Peddamatham on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "InspectorController.h"

//#import "MyDocument.h"
#import "SessionController.h"
#import "SessionManager.h"

#import "Connection.h"
#import "Profile.h"
#import "Session.h"

//#import "NSManagedObjectContext-helper.h"

#include <arpa/inet.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <errno.h>
#include <ifaddrs.h>
#include <stdio.h>


@interface InspectorController ()

@property (readwrite, retain) NSTask *task;   

@property (readwrite, retain) NSMutableData *standardOutput;
@property (readwrite, retain) NSMutableData *standardError;

@end

@implementation InspectorController

@synthesize connections;
@synthesize autoRefresh;
@synthesize resolveHostnames;
@synthesize doneRefresh;
@synthesize showSpinner;

@synthesize task;
@synthesize standardOutput;
@synthesize standardError;


- (id)init 
{
   if (self = [super init])
   {
      connections = [[NSMutableArray alloc] init];             
      self.autoRefresh = NO;
      self.resolveHostnames = NO;
      self.showSpinner = NO;
   }
   
   return self;
}

- (void)dealloc
{
   [connections release];
   [super dealloc];
}

- (void)awakeFromNib
{
   [taskSelectionPopUp selectItemAtIndex:0];
   [autoRefreshButton setEnabled:FALSE];
   [resolveHostnamesButton setEnabled:FALSE];   
}

// -------------------------------------------------------------------------------
//	changeInspectorTask: 
// -------------------------------------------------------------------------------
- (IBAction)changeInspectorTask:(id)sender
{
   //ANSLog(@"InspectorController: changeInspectorTask: %d", [sender tag]);
   
   // I overlayed the Hosts Tableviews for 
   if ([[sender title] hasPrefix:@"See the machines connected"])
   {
      self.autoRefresh = YES;
      [scanButton setTitle:@"Refresh"];
      [self refreshConnectionsList:self];
      [autoRefreshButton setEnabled:TRUE];
      [resolveHostnamesButton setEnabled:TRUE];
      [regularHostsScrollView setHidden:TRUE];
      [netstatHostsScrollView setHidden:FALSE];
   }
   else
   {
      self.autoRefresh = NO;
      [scanButton setTitle:@"Scan"];      
      [autoRefreshButton setEnabled:FALSE];      
      [resolveHostnamesButton setEnabled:FALSE];      
      [regularHostsScrollView setHidden:FALSE];
      [netstatHostsScrollView setHidden:TRUE];      
   }
   
   if ([[sender title] hasPrefix:@"Find computers"])
   {
//      [self searchLocalNetwork:self];
   }
   
   if ([[sender title] hasPrefix:@"Check"])
   {
      [hostsTextField setEnabled:TRUE];
      [hostsTextFieldLabel setEnabled:TRUE];
      [hostsTextField selectText:self];
   }
   else
   {
      [hostsTextField setEnabled:FALSE];
      [hostsTextFieldLabel setEnabled:FALSE];
   }
   
}

// -------------------------------------------------------------------------------
//	launchScan: 
// -------------------------------------------------------------------------------
- (IBAction)launchScan:(id)sender
{
   if ([[taskSelectionPopUp titleOfSelectedItem] hasPrefix:@"Find computers"])
   {
      [self searchLocalNetwork:self];
   }
   else if ([[taskSelectionPopUp titleOfSelectedItem] hasPrefix:@"See the machines"])
   {
      [self refreshConnectionsList:self];
   }
   else if ([[taskSelectionPopUp titleOfSelectedItem] hasPrefix:@"Check what services"])
   {
      [self checkForServices:self];
   }
}

// -------------------------------------------------------------------------------
//	searchLocalNetwork: Wrapper-function for ping-scanning local subnet
// -------------------------------------------------------------------------------
- (IBAction)searchLocalNetwork:(id)sender
{
   // Grab the Session Manager object
   SessionManager *sessionManager = [SessionManager sharedSessionManager];

   // Grab an existing profile
   NSArray *array = [[sessionManager context] fetchObjectsForEntityName:@"Profile"
                                                             withPredicate:@"name = 'Quick Scan'"];
   Profile *profile = [array lastObject];
   
   // Queue and launch the session
   Session *newSession =
   [sessionManager queueSessionWithProfile:profile 
                                withTarget:[NSString stringWithFormat:@"192.168.0.1/%d",[self cidrForInterface:@"en0"]]];
   
   [sessionManager launchSession:newSession];      

}

- (IBAction)checkForServices:(id)sender
{
   // Grab the Session Manager object
   SessionManager *sessionManager = [SessionManager sharedSessionManager];
   
   // Grab an existing profile
   NSArray *array = [[sessionManager context] fetchObjectsForEntityName:@"Profile"
                                                          withPredicate:@"name = 'Quick Scan'"];
   Profile *profile = [array lastObject];
   
   // Queue and launch the session
   Session *newSession =   
   [sessionManager queueSessionWithProfile:profile 
                                withTarget:[hostsTextField stringValue]];
   
   [sessionManager launchSession:newSession];
   
}

// -------------------------------------------------------------------------------
//	cidrForInterface: Gets the CIDR for the passed IP address 
//   TODO: Doing this the lazy way using ifconfig, fix this!!!
// -------------------------------------------------------------------------------
- (int)cidrForInterface:(NSString *)ifName {
   NSAssert(nil != ifName, @"Interface name cannot be nil");
   
   // Prepare a task object
   NSTask *localTask = [[NSTask alloc] init];
   [localTask setLaunchPath:@"/bin/tcsh"];     // For some reason, using /bin/sh screws up the debug console   
   [localTask setArguments:[NSArray arrayWithObjects: @"-c", @"ifconfig | grep netmask | grep 192 | awk '{print $4}'", nil]];
   
   // Create the pipe to read from
   NSPipe *outPipe = [[NSPipe alloc] init];
   [localTask setStandardOutput:outPipe];
   [outPipe release];
   
   // Start the process
   [localTask launch];
   
   // Read the output
   NSData *data = [[outPipe fileHandleForReading]
                   readDataToEndOfFile];
   
   // Make sure the localTask terminates normally
   [localTask waitUntilExit];
   [localTask release];

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

- (IBAction)clickAutoRefresh:(id)sender
{   
   if ((self.autoRefresh == YES) && (self.doneRefresh == YES))
      [self performSelector:@selector(refreshConnectionsList:) withObject:self afterDelay:0.01];
}

- (IBAction)clickResolveHostnames:(id)sender
{
   if ((self.autoRefresh == NO) && (self.doneRefresh == YES))
      [self performSelector:@selector(refreshConnectionsList:) withObject:self afterDelay:0.01];
}

// -------------------------------------------------------------------------------
//	refreshConnectionsList: TODO: This ain't thread-safe.  Fix this.
// -------------------------------------------------------------------------------
- (IBAction)refreshConnectionsList:(id)sender
{
   self.doneRefresh = NO;
      
   self.task = [[[NSTask alloc] init] autorelease];
   
   //ANSLog(@"InspectorController: launchNetstat");
   
   [task setLaunchPath:@"/bin/tcsh"];      
   if (self.resolveHostnames == NO)
      [task setArguments:[NSArray arrayWithObjects: @"-c", @"netstat -d -n -f inet | grep \"tcp\" | grep -v 127 | awk '{print $4, $5, $6 }'", nil]];
   else
      [task setArguments:[NSArray arrayWithObjects: @"-c", @"netstat -d -W -f inet | grep \"tcp\" | grep -v 127 | awk '{print $4, $5, $6 }'", nil]];
   [task setStandardOutput:[NSPipe pipe]];
   [task setStandardError:[NSPipe pipe]];   
   
   self.standardOutput = [[[NSMutableData alloc] init] autorelease];
   self.standardError = [[[NSMutableData alloc] init] autorelease];
   
   NSFileHandle *standardOutputFile = [[task standardOutput] fileHandleForReading];
   NSFileHandle *standardErrorFile = [[task standardError] fileHandleForReading];
   
   [[NSNotificationCenter defaultCenter]
    addObserver:self
    selector:@selector(standardOutNotification:)
    name:NSFileHandleDataAvailableNotification
    object:standardOutputFile];
   [[NSNotificationCenter defaultCenter]
    addObserver:self
    selector:@selector(standardErrorNotification:)
    name:NSFileHandleDataAvailableNotification
    object:standardErrorFile];
   [[NSNotificationCenter defaultCenter]
    addObserver:self
    selector:@selector(terminatedNotification:)
    name:NSTaskDidTerminateNotification
    object:task];
   
   [standardOutputFile waitForDataInBackgroundAndNotify];
   [standardErrorFile waitForDataInBackgroundAndNotify]; 
   
//   [self performSelector:@selector(showSpinnerr) withObject:self afterDelay:1];
   [task launch];
}

// Accessor for the data object
- (NSData *)standardOutputData
{
	return self.standardOutput;
}

// Accessor for the data object
- (NSData *)standardErrorData
{
	return self.standardError;
}

// Reads standard out into the standardOutput data object.
-(void)standardOutNotification: (NSNotification *) notification
{
   NSFileHandle *standardOutFile = (NSFileHandle *)[notification object];
   [standardOutput appendData:[standardOutFile availableData]];
   [standardOutFile waitForDataInBackgroundAndNotify];
}

// Reads standard error into the standardError data object.
-(void)standardErrorNotification: (NSNotification *) notification
{
   NSFileHandle *standardErrorFile = (NSFileHandle *)[notification object];
   [standardError appendData:[standardErrorFile availableData]];
   [standardErrorFile waitForDataInBackgroundAndNotify];
}

- (void)showSpinnerr
{
   if (doneRefresh == NO) {
//      [refreshIndicator startAnimation:self];
      self.showSpinner = YES;
   }
}

// -------------------------------------------------------------------------------
//	terminatedNotification: Called by NTask when Nmap has returned.
// -------------------------------------------------------------------------------
- (void)terminatedNotification:(NSNotification *)notification
{
   //ANSLog(@"InspectorController: terminated");
   
   self.showSpinner = NO;
//   [refreshIndicator stopAnimation:self];
   
   // Clear array
   [connections removeAllObjects];   
   
   // Write the Nmap stdout and stderr buffers out to disk
   NSString *aString =
   [[[NSString alloc]
     initWithData:[self standardOutputData]
     encoding:NSUTF8StringEncoding]
    autorelease];
      
   NSArray *line = [aString componentsSeparatedByString:@"\n"];
   int lineLength = [line count] - 1;
   
   Connection *c = nil;
   NSMutableArray *a = [[NSMutableArray alloc] init];
   
   if (self.resolveHostnames == NO)
   {
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
   }
   else
   {
      for (int i = 0; i < lineLength; i++)
      {
         // Perl, how I miss thee...
         NSArray *p = [[line objectAtIndex:i] componentsSeparatedByString:@" "];
         NSArray *local = [[p objectAtIndex:0] componentsSeparatedByString:@"."];
         NSArray *remote = [[p objectAtIndex:1] componentsSeparatedByString:@"."];
         
         NSString *localIP = [[p objectAtIndex:0] stringByReplacingOccurrencesOfString:[local lastObject] 
                                                                            withString:@""];
         NSString *localPort = [local lastObject];
         
         NSString *remoteIP = [[p objectAtIndex:1] stringByReplacingOccurrencesOfString:[remote lastObject] 
                                                                             withString:@""]; 
         NSString *remotePort = [remote lastObject];
         
         NSString *status = [p objectAtIndex:2];
         
         c = [[Connection alloc] initWithLocalIP:localIP
                                    andLocalPort:localPort
                                     andRemoteIP:remoteIP
                                   andRemotePort:remotePort
                                       andStatus:status];
         [a addObject:c];
      }      
   }
   
   self.doneRefresh = YES;
   
   [connectionsController addObjects:a];

   [[NSNotificationCenter defaultCenter] removeObserver:self];
//   [task release];
   
   
   if (self.autoRefresh == YES)
      [self performSelector:@selector(refreshConnectionsList:) withObject:self afterDelay:2];
}   

@end
