//
//  NetstatController.m
//  recon
//
//  Created by Sumanth Peddamatham on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NetstatController.h"
#import "Connection.h"

@implementation NetstatController

@synthesize connections;

- (id)init 
{
   if (self = [super init])
   {
      connections = [[NSMutableArray alloc] init];    
      
//      Connection *c = [[Connection alloc] init];
//      [connections addObjectsFromArray:[NSArray arrayWithObjects:c,c,c,c,c,c,c,c,c,nil]];
//      [self refreshConnectionsList:self];
   }
   
   return self;
}

// -------------------------------------------------------------------------------
//	chooseTask: 
// -------------------------------------------------------------------------------
- (IBAction)chooseTask:(id)sender
{
   // Determine which button is selected
   int row = [mainSelector selectedRow];
   NSLog(@"Selected: %i", row);
   
   switch (row) {
      case 0:
         [self refreshConnectionsList:self];
         [self autoRefreshConnections];
         break;
      default:
         break;
   }
   
   [mainTabView selectTabViewItemAtIndex:row+1];
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
   // The helper-script prepares the netstat output for us
//   NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"connections" ofType:@"sh"];   
//   NSLog(@"%@", scriptPath);
   
   selectedConnection = [[connectionsController selectedObjects] lastObject];
   
   // Clear array controller
   [[connectionsController content] removeAllObjects];
   
   // Prepare a task object
   NSTask *task = [[NSTask alloc] init];
   [task setLaunchPath:@"/bin/tcsh"];     // For some reason, using /bin/sh screws up the debug console   
   NSArray *args;
   args = [NSArray arrayWithObjects: @"-c", @"netstat -d -n -f inet | grep \"ESTABLISHED\" | grep -v 127 | awk '{print $4, $5, $6 }'", nil];
   [task setArguments:args];
   
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
   int status = [task terminationStatus];
   [task release];
      
   // Check status
//   if (status != 0) {
////      if (outError) {
//         NSDictionary *eDict =
//         [NSDictionary dictionaryWithObject:@"zipinfo failed"
//                                     forKey:NSLocalizedFailureReasonErrorKey];
////         *outError = [NSError errorWithDomain:NSOSStatusErrorDomain
////                                         code:0
////                                     userInfo:eDict];
////      }
//      return NO;
//   }
   
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
