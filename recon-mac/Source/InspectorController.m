//
//  InspectorController.m
//  Recon
//
//  Created by Sumanth Peddamatham on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "InspectorController.h"
#import "SessionController.h"
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


@interface InspectorController ()

@property (readwrite, retain) NSTask *task;   

@property (readwrite, retain) NSMutableData *standardOutput;
@property (readwrite, retain) NSMutableData *standardError;

@property (readwrite, retain)BonjourListener *bonjourListener;

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

@synthesize bonjourListener;
@synthesize foundServices;

- (id)init 
{
   if (self = [super init])
   {
      connections = [[NSMutableArray alloc] init];             
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
      
      root = [[NSMutableDictionary new] retain];                  
   }
   
   return self;
}

- (void)dealloc
{
   [connections release];
   [foundServices release];
   [root release];
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
   //NSLog(@"InspectorController: changeInspectorTask: %d", [sender tag]);
   if ([[sender title] hasPrefix:@"Find Bonjour"])
   {
      self.autoRefresh = NO;
      [scanButton setTitle:@"Scan"];      
      [autoRefreshButton setEnabled:FALSE];      
      [resolveHostnamesButton setEnabled:FALSE]; 
      
      [regularHostsScrollView setHidden:TRUE];
      [netstatHostsScrollView setHidden:TRUE];      
      [bonjourHostsScrollView setHidden:FALSE];          
   }
   else if ([[sender title] hasPrefix:@"See the machines connected"])
   {
      self.autoRefresh = YES;
      [scanButton setTitle:@"Refresh"];
      [self refreshConnectionsList:self];
      [autoRefreshButton setEnabled:TRUE];
      [resolveHostnamesButton setEnabled:TRUE];
      
      [regularHostsScrollView setHidden:TRUE];
      [netstatHostsScrollView setHidden:FALSE];      
      [bonjourHostsScrollView setHidden:TRUE];          
   }  
   else
   {
      self.autoRefresh = NO;
      [scanButton setTitle:@"Scan"];      
      [autoRefreshButton setEnabled:FALSE];      
      [resolveHostnamesButton setEnabled:FALSE]; 
      
      [regularHostsScrollView setHidden:FALSE];
      [netstatHostsScrollView setHidden:TRUE];      
      [bonjourHostsScrollView setHidden:TRUE];          
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
   else if ([[taskSelectionPopUp titleOfSelectedItem] hasPrefix:@"Find Bonjour"])
   {
      [bonjourListener search:self];
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
   NSLog(@"InspectorController: refreshConnectionsList");
   
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
//   [task release];
   
   
   if (self.autoRefresh == YES)
      [self performSelector:@selector(refreshConnectionsList:) withObject:self afterDelay:2];
}   


#pragma mark Bonjour Listener
// -------------------------------------------------------------------------------
//	foundBonjourServices: 
// -------------------------------------------------------------------------------
- (void)foundBonjourServices:(NSNotification *)notification
{
   NSLog(@"InspectorController: found services");

   NSMutableDictionary *newService = [[[notification object] retain] autorelease];
   
   NSString *key = [NSString stringWithFormat:@"%@", 
                    [newService objectForKey:@"Long_Type"]];                    
//   [root setObject:[[notification object] retain] forKey:key];
   [root setObject:newService forKey:key];
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
#pragma mark Bonjour Listener OutlineView Delegates   

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
   // The NSOutlineView calls this when it needs to know how many children
   // a particular item has. Because we are using a standard tree of NSDictionary,
   // NSArray, NSString etc objects, we can just return the count.
   
   // The root node is special; if the NSOutline view asks for the children of nil,
   // we give it the count of the root dictionary.
   
   if (item == nil)
   {
      return [root count];
   }
   
   // If it's an NSArray or NSDictionary, return the count.
   
   if ([item isKindOfClass:[NSDictionary class]] || [item isKindOfClass:[NSArray class]])
   {
      return [item count];
   }
   
   // It can't have children if it's not an NSDictionary or NSArray.
   
   return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
   // NSOutlineView calls this when it needs to know if an item can be expanded.
   // In our case, if an item is an NSArray or NSDictionary AND their count is > 0
   // then they are expandable.
   
   if ([item isKindOfClass:[NSArray class]] || [item isKindOfClass:[NSDictionary class]])
   {
      if ([item count] > 0)
         return YES;
   }
   
   // Return NO in all other cases.
   
   return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
   // NSOutlineView will iterate over every child of every item, recursively asking
   // for the entry at each index. We return the item at a given array index,
   // or at the given dictionary key index.
   if (item == nil)
   {
      item = root;
   }
   
   if ([item isKindOfClass:[NSArray class]])
   {
      return [item objectAtIndex:index];
   }
   else if ([item isKindOfClass:[NSDictionary class]])
   {
      return [item objectForKey:[[item allKeys] objectAtIndex:index]];
   }
   
   return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
   // NSOutlineView calls this for each column in your NSOutlineView, for each item.
   // You need to work out what you want displayed in each column; in our case we
   // create in Interface Builder two columns, one called "Key" and the other "Value".
   //
   // If the NSOutlineView is after the key for an item, we use either the NSDictionary
   // key for that item, or we count from 0 for NSArrays.
   //
   // Note that you can find the parent of a given item using [outlineView parentForItem:item];
   
   if ([[[tableColumn headerCell] stringValue] compare:@"Key"] == NSOrderedSame)
   {
      // Return the key for this item. First, get the parent array or dictionary.
      // If the parent is nil, then that must be root, so we'll get the root
      // dictionary.
      
      id parentObject = [outlineView parentForItem:item] ? [outlineView parentForItem:item] : root;
      
      if ([parentObject isKindOfClass:[NSDictionary class]])
      {
         // Dictionaries have keys, so we can return the key name. We'll assume
         // here that keys/objects have a one to one relationship.
         return [[parentObject allKeysForObject:item] objectAtIndex:0];
      }
      else if ([parentObject isKindOfClass:[NSArray class]])
      {
         // Arrays don't have keys (usually), so we have to use a name
         // based on the index of the object.
         
         return [NSString stringWithFormat:@"Item %d", [parentObject indexOfObject:item]];
      }
   }
   else
   {
      // Return the value for the key. If this is a string, just return that.
      
      if ([item isKindOfClass:[NSString class]])
      {
         return item;
      }
      else if ([item isKindOfClass:[NSDictionary class]])
      {
         return [NSString stringWithFormat:@"%d items", [item count]];
      }
      else if ([item isKindOfClass:[NSArray class]])
      {
         return [NSString stringWithFormat:@"%d items", [item count]];
      }
   }
   
   return nil;
}

@end
