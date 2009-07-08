//
//  NmapController.m
//  recon
//
//  Created by Sumanth Peddamatham on 7/1/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//

#import "NmapController.h"

@implementation NmapController

- (id) initWithNmapBinary:(NSString *)nmapBinary 
                 withArgs:(NSArray *)nmapArgs 
       withOutputFilePath:(NSString *)oFilePath;
{
   if (self = [super init]) 
   {
      task = [[NSTask alloc] init];
      
      [task setLaunchPath:nmapBinary];
      [task setArguments:nmapArgs];
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
      
      outputFilePath = [oFilePath retain];      
   }
   
   return self;
}

- (void) startScan
{
   // TODO: Check for error on task launch
   
	[task launch];   
   isRunning = TRUE;
   
   // If error, send unsuccessfulLaunch notification
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
      
      isRunning = FALSE;
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
//   NSLog(@"%@", outputString);
//   NSLog(@"%@", errorString);
   
   NSError *error;
   NSString *standardOutPath = [outputFilePath stringByAppendingPathComponent:@"nmap-stdout.txt"];
   NSString *standardErrPath = [outputFilePath stringByAppendingPathComponent:@"nmap-stdout.txt"];
   
   // Write standardOut and standardError to file
   BOOL ok = [outputString writeToFile:standardOutPath atomically:YES 
                              encoding:NSUnicodeStringEncoding error:&error];
   ok = [errorString writeToFile:standardErrPath atomically:YES 
                              encoding:NSUnicodeStringEncoding error:&error];

}

- (void)dealloc
{
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc removeObserver:self];
   [super dealloc];
}

@end
