//
//  NmapController.m
//  Recon
//
//  Created by Sumanth Peddamatham on 7/1/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//

#import "NmapController.h"

@interface NmapController ()

@property (readwrite, retain) NSTask *task;   

@property (readwrite, retain) NSMutableData *standardOutput;
@property (readwrite, retain) NSMutableData *standardError;
@property (readwrite, retain) NSString *outputFilePath;
@property (readwrite, assign) BOOL hasRun;

@end


@implementation NmapController

@synthesize task;
@synthesize standardOutput;
@synthesize standardError;
@synthesize outputFilePath;
@synthesize hasRun;

// -------------------------------------------------------------------------------
//	initWithNmapBinary
// -------------------------------------------------------------------------------
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
      
      self.outputFilePath = oFilePath;
   }
   
   return self;
}

- (void)dealloc
{   
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc removeObserver:self];
      
//   [standardOutput release];
//   [standardError release];
   [outputFilePath release];   
   [task release];
   
   [super dealloc];
}

// -------------------------------------------------------------------------------
//	isRunning: Directly return status of task.
// -------------------------------------------------------------------------------
- (BOOL) isRunning
{
   return [task isRunning];
}

// -------------------------------------------------------------------------------
//	startScan:
// -------------------------------------------------------------------------------
- (void) startScan
{
   // Mark this session as run
   self.hasRun = TRUE;
   
   // TODO: Check for error on task launch   
   @try
   {
      [task launch];   
   }
   @catch (NSException *exception)
   {
      // If error, send unsuccessfulLaunch notification      
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];      
      [nc postNotificationName:@"NCunsuccessfulRun" object:self];               
   }
}

// -------------------------------------------------------------------------------
//	abortScan: If task running, abort and send a successfulAbort notification.
//            If task not running, assume its already completed and fake the notification.
// -------------------------------------------------------------------------------
- (void)abortScan
{
   if ([task isRunning])
   {  
      //ANSLog(@"NmapController: Abort: Terminating Task!");      
      [task terminate];      
   }
   else
   {
      //ANSLog(@"NmapController: Abort: Task already stopped, faking it!");      
      self.hasRun = TRUE;
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];      
      [nc postNotificationName:@"NCabortedRun" object:self]; 
   }
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


// -------------------------------------------------------------------------------
//	writeNmapOutputToFile: Write task stdout and stderr to disk.
// -------------------------------------------------------------------------------
- (BOOL)writeNmapOutputToFile
{
   // Write the Nmap stdout and stderr buffers out to disk
   NSString *outputString =
   [[[NSString alloc]
     initWithData:[self standardOutputData]
     encoding:NSUTF8StringEncoding]
    autorelease];
   NSString *errorString =   
   [[[NSString alloc]
     initWithData:[self standardErrorData]
     encoding:NSUTF8StringEncoding]
    autorelease];
   
   // Check for errors, and send SessionController a:
   //  - successfulTermination
   //  - unsuccessfulTermination
   
   // TODO: Parse errorString and notify if errors occurred.
   //   //ANSLog(@"%@", outputString);
   //   //ANSLog(@"%@", errorString);
   
   NSError *error;
   NSString *standardOutPath = [outputFilePath stringByAppendingPathComponent:@"nmap-stdout.txt"];
   NSString *standardErrPath = [outputFilePath stringByAppendingPathComponent:@"nmap-stderr.txt"];
   
   // Write standardOut and standardError to file
   BOOL 
   ok = [outputString writeToFile:standardOutPath atomically:YES 
                              encoding:NSUnicodeStringEncoding error:&error];
   ok = [errorString writeToFile:standardErrPath atomically:YES 
                        encoding:NSUnicodeStringEncoding error:&error];
   
   return ok;
}

// -------------------------------------------------------------------------------
//	terminatedNotification: Called by NTask when Nmap has returned.
// -------------------------------------------------------------------------------
- (void)terminatedNotification:(NSNotification *)notification
{
   //ANSLog(@"NmapController: Received task termination!");
 
   // Write stdout and stderr to file
   BOOL writeOK = [self writeNmapOutputToFile];

   int taskReturnValue = [[notification object] terminationStatus];   
   //ANSLog(@"NmapController: Return value: %i", taskReturnValue);

   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

   // Check for errors
   switch (taskReturnValue) {
      // SUCCESS
      case 0:
         // TODO: Grep stdout to make sure the help flag wasn't set.
         [nc postNotificationName:@"NCsuccessfulRun" object:self];         
         break;
//      // ROOT REQUIRED!
//      case 1:
//         break;
      // TASK KILLED         
      case 15:
         [nc postNotificationName:@"NCabortedRun" object:self];         
         break;
      // ERROR
      case 1:         
      case 255:
         [nc postNotificationName:@"NCunsuccessfulRun" object:self];         
         break;
         
      default:
         break;
   }
}


@end
