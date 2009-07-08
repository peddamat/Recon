//
//  NmapController.m
//  nmapX-coredata
//
//  Created by Sumanth Peddamatham on 7/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NmapController.h"

@implementation NmapController


- (void) launchScan:(NSString *)nmapBinary withArgs:(NSArray *)args withOutputFile:(NSString *)outputFile
{
   
   task = [[NSTask alloc] init];
   
	[task setLaunchPath:nmapBinary];
	[task setArguments:args];
	[task setStandardOutput:[NSPipe pipe]];
	[task setStandardError:[NSPipe pipe]];   

   standardOutput = [[NSMutableData alloc] init];
   standardError = [[NSMutableData alloc] init];
   
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
   
   // TODO: Check for error on task launch
   
	[task launch];   
   
   // If error, send unsuccessfulLaunch
}

- (void)readProgress
{
}


// If task running, abort and send successfulAbor   
// If task not running, assume it completed already and return
- (void)abortScan
{
   if ([task isRunning])
   {
      [task terminate];
//      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//      [nc postNotificationName:@"sessionTerminated" object:self];      
   }
}

// Accessor for the data object
- (NSData *)standardOutputData
{
	return standardOutput;
}

// Accessor for the data object
- (NSData *)standardErrorData
{
	return standardError;
}

//
// standardOutNotification:
//
// Reads standard out into the standardOutput data object.
//
// Parameters:
//    notification - the notification containing the NSFileHandle to read
//
-(void)standardOutNotification: (NSNotification *) notification
{
   NSFileHandle *standardOutFile = (NSFileHandle *)[notification object];
   [standardOutput appendData:[standardOutFile availableData]];
   [standardOutFile waitForDataInBackgroundAndNotify];
}

//
// standardErrorNotification:
//
// Reads standard error into the standardError data object.
//
// Parameters:
//    notification - the notification containing the NSFileHandle to read
//
-(void)standardErrorNotification: (NSNotification *) notification
{
   NSFileHandle *standardErrorFile = (NSFileHandle *)[notification object];
   [standardError appendData:[standardErrorFile availableData]];
   [standardErrorFile waitForDataInBackgroundAndNotify];
}

- (void)terminatedNotification: (NSNotification *)notification
{
   NSLog(@"NmapController: Received task termination!");
   
   outputString =
   [[[NSString alloc]
     initWithData:[self standardOutputData]
     encoding:NSUTF8StringEncoding]
    autorelease];
   errorString =
   [[[NSString alloc]
     initWithData:[self standardErrorData]
     encoding:NSUTF8StringEncoding]
    autorelease];
   
   // Check for errors, and send SessionController a:
   //  - successfulTermination
   //  - unsuccessfulTermination
   
   // TODO: Parse errorString and notify if errors occurred.
   NSLog(@"%@", outputString);
   NSLog(@"%@", errorString);   
}

@end
