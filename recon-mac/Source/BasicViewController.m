//
//  InspectorController.m
//  Recon
//
//  Created by Sumanth Peddamatham on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BasicViewController.h"

#import "SessionManager.h"
#import "NetstatConnection.h"
#import "Profile.h"
#import "Session.h"

#import "BonjourListener.h"
#import "SPGrowlController.h"

#include <arpa/inet.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <errno.h>
#include <ifaddrs.h>
#include <stdio.h>

#include "NSManagedObjectContext-helper.h"

@interface BasicViewController ()

   @property (readwrite, retain) NSTask *task;   

   @property (readwrite, retain) NSMutableData *standardOutput;
   @property (readwrite, retain) NSMutableData *standardError;

   @property (readwrite, retain)BonjourListener *bonjourListener;

@end

@implementation BasicViewController

@synthesize connections;
@synthesize autoRefresh;
@synthesize resolveHostnames;
@synthesize doneRefresh;
@synthesize showSpinner;

@synthesize task;
@synthesize standardOutput;
@synthesize standardError;

@synthesize bonjourListener;
@synthesize foundServices;

@synthesize targetBarBasicContent;

- (id)init 
{
   if (self = [super init])
   {
      if (![super initWithNibName:@"Basic"
                           bundle:nil]) {
         return nil;
      }
      [self setTitle:@"Basic"];      
      
      self.connections = [[NSMutableArray alloc] init];             
      self.autoRefresh = NO;
      self.resolveHostnames = NO;
      self.showSpinner = NO;
      self.bonjourListener = [[BonjourListener alloc] init];
      self.foundServices = [[NSMutableArray alloc] init];
      
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
      [nc addObserver:self
             selector:@selector(foundBonjourServices:)
                 name:@"BAFfoundBonjourServices"
               object:nil];                  
   }
   
   return self;
}

- (void)dealloc
{
   [task release];
   
   [connections release];
   [foundServices release];
   
   [super dealloc];
}

- (void)awakeFromNib
{
   [taskSelectionPopUp selectItemAtIndex:0];
   [autoRefreshButton setEnabled:FALSE];
   [resolveHostnamesButton setEnabled:FALSE];   
   
   [targetBarBasicContent retain];   
   [self createNetstatMenu];   
}

#pragma mark -

// -------------------------------------------------------------------------------
//	launchScan: 
// -------------------------------------------------------------------------------
- (IBAction)launchScan:(id)sender
{
   
   if ([[taskSelectionPopUp titleOfSelectedItem] hasPrefix:@"Find computers"])
   {
      // Unselect all sessions to prevent users from thinking an old
      // session's results are the new results
      [sessionsArrayController setSelectionIndex:1000];
      
      [self searchLocalNetwork:self];
   }
   else if ([[taskSelectionPopUp titleOfSelectedItem] hasPrefix:@"See the machines"])
   {
      [self refreshConnectionsList:self];
   }
   else if ([[taskSelectionPopUp titleOfSelectedItem] hasPrefix:@"Check what services"])
   {
      // Unselect all sessions to prevent users from thinking an old
      // session's results are the new results
      [sessionsArrayController setSelectionIndex:1000];
      
      [self checkForServices:self];
   }
   else if ([[taskSelectionPopUp titleOfSelectedItem] hasPrefix:@"Find Bonjour"])
   {
      [bonjourListener search:self];
   }
   
}

// -------------------------------------------------------------------------------
//	changeInspectorTask: 
// -------------------------------------------------------------------------------
- (IBAction)changeInspectorTask:(id)sender
{
   //NSLog(@"InspectorController: changeInspectorTask: %d", [sender tag]);
      
   if ([[sender title] hasPrefix:@"Find Bonjour"])
   {
      self.autoRefresh = NO;
      [scanButton setTitle:@"Scan"];      
      [autoRefreshButton setEnabled:FALSE];      
      [resolveHostnamesButton setEnabled:FALSE]; 
      
      [workspaceBasicContentBonjour setFrame:[workspacePlaceholder frame]];
      [[workspacePlaceholder animator] replaceSubview:[[workspacePlaceholder subviews] lastObject]
                                                 with:workspaceBasicContentBonjour];
      
      
   }
   else if ([[sender title] hasPrefix:@"See the machines connected"])
   {
      self.autoRefresh = YES;
      [scanButton setTitle:@"Refresh"];
      [self refreshConnectionsList:self];
      [autoRefreshButton setEnabled:TRUE];
      [resolveHostnamesButton setEnabled:TRUE];
      
      [workspaceBasicContentNetstat setFrame:[workspacePlaceholder frame]];
      [[workspacePlaceholder animator] replaceSubview:[[workspacePlaceholder subviews] lastObject]
                                                 with:workspaceBasicContentNetstat];
            
   }  
   else
   {      
      self.autoRefresh = NO;
      [scanButton setTitle:@"Scan"];      
      [autoRefreshButton setEnabled:FALSE];      
      [resolveHostnamesButton setEnabled:FALSE]; 

      [workspaceBasicContent setFrame:[workspacePlaceholder frame]];
      [[workspacePlaceholder animator] replaceSubview:[[workspacePlaceholder subviews] lastObject]
                                                 with:workspaceBasicContent];
      
   }
   
   if ([[sender title] hasPrefix:@"Check"])
   {
   }
   else
   {
   }
}

#pragma mark -
#pragma mark Blah

// -------------------------------------------------------------------------------
//	searchLocalNetwork: Wrapper-function for Quick Scan-ing local subnet
// -------------------------------------------------------------------------------
- (IBAction)searchLocalNetwork:(id)sender
{
   // Grab the Session Manager object
   SessionManager *sessionManager = [SessionManager sharedSessionManager];

   // Grab the Quick Scan profile
   NSArray *array = [managedObjectContext fetchObjectsForEntityName:@"Profile"
                                                             withPredicate:@"name = 'Quick Scan'"];
   Profile *profile = [array lastObject];
   
   // Grab default route using 'route' (HACKY)
   // Prepare a task object
   NSTask *localTask = [[NSTask alloc] init];
   [localTask setLaunchPath:@"/bin/tcsh"];     // For some reason, using /bin/sh screws up the debug console   
   [localTask setArguments:[NSArray arrayWithObjects: @"-c", @"route -n get default | grep gateway | tail -n 1 | awk '{print $2}'", nil]];
   
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
   NSString *defaultIp = [[[NSString alloc] initWithData:data
                                             encoding:NSUTF8StringEncoding] autorelease];
   
   defaultIp = [defaultIp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
   
   // Queue and launch the session
   Session *newSession =
   [sessionManager queueSessionWithProfile:profile 
                                withTarget:[NSString stringWithFormat:@"%@/%d", defaultIp, [self cidrForInterface:@"en0"]]];
      
   [sessionManager launchSession:newSession];      
}

- (IBAction)checkForServices:(id)sender
{
   // Grab the Session Manager object
   SessionManager *sessionManager = [SessionManager sharedSessionManager];
   
   // Grab the Quick Scan profile
   NSArray *array = [managedObjectContext fetchObjectsForEntityName:@"Profile"
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
- (int)cidrForInterface:(NSString *)ifName 
{
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
   [[connectionsController content] removeAllObjects];
   
   // Write the Nmap stdout and stderr buffers out to disk
   NSString *aString =
   [[[NSString alloc]
     initWithData:[self standardOutputData]
     encoding:NSUTF8StringEncoding]
    autorelease];
      
   NSArray *line = [aString componentsSeparatedByString:@"\n"];
   int lineLength = [line count] - 1;
   
   NetstatConnection *c = nil;
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
         
         c = [[NetstatConnection alloc] initWithLocalIP:localIP
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
         
         // TODO: This is buggy.  ie. if the protocol is 'aol', and the address is 'www.aol.com.aol'
         //       both 'aol's are stripped.  We need to just remove the trailing instance.
         NSString *localIP = [[p objectAtIndex:0] stringByReplacingOccurrencesOfString:[local lastObject] 
                                                                            withString:@""];
         localIP = [localIP stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
         
         NSString *localPort = [local lastObject];
         
         NSString *remoteIP = [[p objectAtIndex:1] stringByReplacingOccurrencesOfString:[remote lastObject] 
                                                                             withString:@""]; 
         remoteIP = [remoteIP stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
                     
         NSString *remotePort = [remote lastObject];
         
         NSString *status = [p objectAtIndex:2];
         
         c = [[NetstatConnection alloc] initWithLocalIP:localIP
                                    andLocalPort:localPort
                                     andRemoteIP:remoteIP
                                   andRemotePort:remotePort
                                       andStatus:status];
         [a addObject:c];
      }      
   }
   
   self.doneRefresh = YES;
   
   [connectionsController addObjects:a];

   [[NSNotificationCenter defaultCenter] removeObserver:self
                                                   name:NSFileHandleDataAvailableNotification
                                                 object:nil];
   [[NSNotificationCenter defaultCenter] removeObserver:self
                                                   name:NSTaskDidTerminateNotification
                                                 object:nil];      
   
   if (self.autoRefresh == YES)
      [self performSelector:@selector(refreshConnectionsList:) withObject:self afterDelay:2];
}   

#pragma mark -
#pragma mark Bonjour Listener

// -------------------------------------------------------------------------------
//	foundBonjourServices: 
// -------------------------------------------------------------------------------
- (void)foundBonjourServices:(NSNotification *)notification
{
   NSLog(@"InspectorController: found services");

   NSMutableDictionary *newService = [[notification object] retain];
   
   NSString *key = [NSString stringWithFormat:@"%@ on %@", 
                    [newService objectForKey:@"Long_Type"], [newService objectForKey:@"Name"]];                    

   [bonjourConnectionsController addObject:newService];
   
   [foundServicesOutlineView reloadData];
   
	[[SPGrowlController sharedGrowlController] 
    notifyWithTitle:@"Found Bonjour Service" 
    description:[NSString stringWithFormat: @"Type: %@\nIP Address: %@", [newService objectForKey:@"Long_Type"], [newService objectForKey:@"IP_Address"]] 
    notificationName:@"Connected"];  
   
//   [foundServicesController removeObjects:[foundServicesController arrangedObjects]];
//   [foundServicesController addObjects:[[notification object] foundServices]];
//   
//   for (NSDictionary *dict in self.foundServices)
//   {
//      NSLog(@"---------------------------");
//      for (id dictKey in [dict allKeys])
//      {
//         
//         NSData *dictValue = [dict valueForKey:dictKey];
////         NSString *aStr = [[NSString alloc] initWithData:dictValue encoding:NSASCIIStringEncoding]; 
//         NSLog(@"%@: %@", dictKey, dictValue);
//      }
//      NSLog(@"---------------------------\n");      
//   }
}

#pragma mark -
#pragma mark Table click handlers

// -------------------------------------------------------------------------------
//	createNetstatMenu: 
// -------------------------------------------------------------------------------
- (void)createNetstatMenu
{
   NSArray *array = [[self managedObjectContext] fetchObjectsForEntityName:@"Profile" withPredicate:
                     @"(parent.name LIKE[c] 'Defaults') OR (parent.name LIKE[c] 'User Profiles')"];   
   
   NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                       initWithKey:@"name" ascending:YES];
   
   NSMutableArray *sa = [NSMutableArray arrayWithArray:array];
   [sa sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];    
   [sortDescriptor release];
   
   NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:@"Queue with"
                                               action:@selector(handleNetstatMenuClick:)
                                        keyEquivalent:@""];   
   NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"Profile"];
   [mi setSubmenu:submenu];
   
   for (id obj in sa)
   {
      NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:[obj name]
                                                  action:@selector(handleNetstatMenuClick:)
                                           keyEquivalent:@""];
      [mi setTag:10];
      [submenu addItem:mi];
      [mi release];      
      
   }
   [netstatContextMenu addItem:mi];
}

// -------------------------------------------------------------------------------
//	handleNetstatMenuClick: 
// -------------------------------------------------------------------------------
- (IBAction)handleNetstatMenuClick:(id)sender
{
   //ANSLog(@"MyDocument: handleHostsMenuClick: %@", [sender title]);
   
   // If we want to queue selected hosts... (10 is a magic number specified in IB)
   if ([sender tag] == 10)
   {
      // Grab the desired profile...
      NSArray *s = [[self managedObjectContext] fetchObjectsForEntityName:@"Profile" withPredicate:
                    @"(name LIKE[c] %@)", [sender title]]; 
      Profile *p = [s lastObject];
      
      // Grab the selected hosts from the hostsController
      NSArray *selectedHosts = [connectionsController selectedObjects];
      
      NSString *hostsIpCSV = [[NSString alloc] init];
      
      // Create a comma-seperated string of target ip's
      if ([selectedHosts count] > 1)
      {
         NetstatConnection *lastHost = [selectedHosts lastObject];
         
         for (NetstatConnection *host in selectedHosts)
         {
            if (host == lastHost)
               break;
            hostsIpCSV = [hostsIpCSV stringByAppendingFormat:@"%@ ", [host remoteIP]];
         }
      }
      
      hostsIpCSV = [hostsIpCSV stringByAppendingString:[[selectedHosts lastObject] remoteIP]];
      
      //      // Create a Target string based on the hosts ip's
      //      NSString *ip = [[a lastObject] ipv4Address];
      
      // BEAUTIFIER: When queueing up a new host, keep the selection on the current Session
      Session *currentSession = [[sessionsArrayController selectedObjects] lastObject];      
      
      // Grab the Session Manager object
      SessionManager *sessionManager = [SessionManager sharedSessionManager];
      
      [sessionManager queueSessionWithProfile:p withTarget:hostsIpCSV];
      
      // BEAUTIFIER
      [sessionsArrayController setSelectedObjects:[NSArray arrayWithObject:currentSession]];
   }
}

// Enable/Disable menu depending on context
//- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
//{
//   NSLog(@"ASD");
//   return YES;
//}   
//
// Handle context menu clicks in Sessions TableView
//- (void)menuNeedsUpdate:(NSMenu *)menu 
//{
//   NSLog(@"Aasdf");   
//}   

#pragma mark -
#pragma mark Sort Descriptors

// -------------------------------------------------------------------------------
//	Sort Descriptors for the various table views
// -------------------------------------------------------------------------------

// http://fadeover.org/blog/archives/13
- (NSArray *)hostSortDescriptor
{
	if(hostSortDescriptor == nil){
		hostSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"ipv4Address" ascending:YES]];
   }
   
	return hostSortDescriptor;
}

- (void)setHostSortDescriptor:(NSArray *)newSortDescriptor
{
	hostSortDescriptor = newSortDescriptor;
}

- (NSArray *)portSortDescriptor
{
	if(portSortDescriptor == nil){
		portSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"number" ascending:YES]];
   }
   
	return portSortDescriptor;
}

- (void)setPortSortDescriptor:(NSArray *)newSortDescriptor
{
	portSortDescriptor = newSortDescriptor;
}

- (NSArray *)profileSortDescriptor
{
	if(profileSortDescriptor == nil){
		profileSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]];
   }
   
	return profileSortDescriptor;
}

- (void)setProfileSortDescriptor:(NSArray *)newSortDescriptor
{
	profileSortDescriptor = newSortDescriptor;
}

- (NSArray *)sessionSortDescriptor
{
	if(sessionSortDescriptor == nil){
		sessionSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO]];
   }
   
	return sessionSortDescriptor;
}

- (void)setSessionSortDescriptor:(NSArray *)newSortDescriptor
{
	sessionSortDescriptor = newSortDescriptor;
}

- (NSArray *)osSortDescriptor
{
	if(osSortDescriptor == nil){
		osSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO]];
   }
   
	return osSortDescriptor;
}

- (void)setOsSortDescriptor:(NSArray *)newSortDescriptor
{
	osSortDescriptor = newSortDescriptor;
}

@end
