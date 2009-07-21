//
//  InspectorController.m
//  Recon
//
//  Created by Sumanth Peddamatham on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "InspectorController.h"

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


@implementation InspectorController

@synthesize connections;
@synthesize autoRefresh;
@synthesize resolveHostnames;

- (id)init 
{
   if (self = [super init])
   {
      connections = [[NSMutableArray alloc] init];             
      self.autoRefresh = TRUE;
      self.resolveHostnames = FALSE;
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
   NSLog(@"InspectorController: changeInspectorTask: %d", [sender tag]);
   
   // I overlayed the Hosts Tableviews for 
   if ([[sender title] hasPrefix:@"See the machines connected"])
   {
      [scanButton setTitle:@"Refresh"];
      [self refreshConnectionsList:self];
      [autoRefreshButton setEnabled:TRUE];
      [resolveHostnamesButton setEnabled:TRUE];
      [regularHostsScrollView setHidden:TRUE];
      [netstatHostsScrollView setHidden:FALSE];
   }
   else
   {
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
   
   if ([[sender title] hasPrefix:@"Check what services"])
   {
      [hostsTextField setEnabled:TRUE];
      [hostsTextFieldLabel setEnabled:TRUE];
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
      // Grab the Session Manager object
      SessionManager *sessionManager = [SessionManager sharedSessionManager];
      
      [sessionManager processQueue];   
   }
   else if ([[taskSelectionPopUp titleOfSelectedItem] hasPrefix:@"See the machines"])
   {
      [self refreshConnectionsList:self];
   }
}

// -------------------------------------------------------------------------------
//	searchLocalNetwork: Wrapper-function for ping-scanning local subnet
// -------------------------------------------------------------------------------
- (IBAction)searchLocalNetwork:(id)sender
{
   // Grab the Session Manager object
   SessionManager *sessionManager = [SessionManager sharedSessionManager];

   // Create a profile and populate it for basic ping-scanning
   Profile *profile = [NSEntityDescription insertNewObjectForEntityForName:@"Profile" 
                                                    inManagedObjectContext:[sessionManager context]];
   
   [profile setFastScan:[NSNumber numberWithBool:TRUE]];
   
   // Queue and launch the session
   [sessionManager queueSessionWithProfile:profile 
                                withTarget:[NSString stringWithFormat:@"192.168.0.1/%d",[self cidrForInterface:@"en0"]]];

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
//	refreshConnectionsList: TODO: This ain't thread-safe.  Fix this.
// -------------------------------------------------------------------------------
- (IBAction)refreshConnectionsList:(id)sender
{    
   doneRefresh = NO;
   
   NSLog(@"InspectorController: refreshConnectionsList");
      
//   selectedConnection = [[connectionsController selectedObjects] lastObject];
   
   // Clear array
   [connections removeAllObjects];
   
   // Prepare a task object
   NSTask *task = [[NSTask alloc] init];
   [task setLaunchPath:@"/bin/tcsh"];     // For some reason, using /bin/sh screws up the debug console   
   
   // Prepare the netstat munging line
   if (self.resolveHostnames == NO)
      [task setArguments:[NSArray arrayWithObjects: @"-c", @"netstat -d -n -f inet | grep \"tcp\" | grep -v 127 | awk '{print $4, $5, $6 }'", nil]];
   else
      [task setArguments:[NSArray arrayWithObjects: @"-c", @"netstat -d -W -f inet | grep \"tcp\" | grep -v 127 | awk '{print $4, $5, $6 }'", nil]];
   
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
     
   [connectionsController addObjects:a];
   
//   if (selectedConnection != nil)
//      [connectionsController setSelectedObjects:[NSArray arrayWithObject:selectedConnection]];
//   else
//      [connectionsController setSelectionIndex:0];
   
   // Release the string
   [aString release];
      
   doneRefresh = YES;
   
   if (self.autoRefresh == YES)
      [self performSelector:@selector(refreshConnectionsList:) withObject:self afterDelay:1];
}

- (IBAction)clickAutoRefresh:(id)sender
{
   self.resolveHostnames = NO;
   
   if ((self.autoRefresh == YES) && (doneRefresh == YES))
   {
      [self performSelector:@selector(refreshConnectionsList:) withObject:self afterDelay:0.01];
   }
}

- (IBAction)clickResolveHostnames:(id)sender
{
   self.autoRefresh = NO;
   [self refreshConnectionsList:self];
}
@end
