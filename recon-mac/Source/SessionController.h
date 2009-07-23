//
//  ScanController.h
//  Recon
//
//  Created by Sumanth Peddamatham on 7/1/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//
//  - Handles 'Begin scan' button from UI
//
//  - Check User Preferences for session directory
//    - Creates a directory for the new session
//    - 
//
//  - Uses ArgumentListGenerator to create nmap args from managedObject in UI
//
//  - Uses NmapController to create an NSTask to launch nmap with args from
//    ArgumentListGenerator.
//
//  - Once NmapController indicates scan complete, uses XMLController to 
//    parse output file and update managedObject in UI.
//

#import <Cocoa/Cocoa.h>

@class Session;
@class Profile;
@class NmapController;
@class XMLController;

@interface SessionController : NSObject {
   
   Session *session; 
   NSString *sessionUUID;   
   NSString *sessionDirectory;
   NSString *sessionOutputFile;   
   
   BOOL hasReconRunBefore;   
   BOOL isRunning;
   BOOL deleteAfterAbort;
   
   NSArray *nmapArguments;   
   NmapController *nmapController;
   
   NSTimer *resultsTimer;
   XMLController *xmlController;
}

@property (readonly, assign) BOOL hasReconRunBefore;
@property (readonly, assign) BOOL isRunning;
@property (readwrite, retain) Session *session;
@property (readonly, retain) NSString *sessionUUID;

- (void) initWithProfile:(Profile *)profile 
                     withTarget:(NSString *)sessionTarget   
         inManagedObjectContext:(NSManagedObjectContext *)context;

- (void)initWithSession:(Session *)s;

- (Profile *)copyProfile:(Profile *)profile;
- (BOOL)createSessionDirectory:(NSString *)uuid;

- (void)initNmapController;
- (void)startScan;
- (void)abortScan;
- (void)deleteSession;

+ (NSString *) stringWithUUID;

- (void)readProgress:(NSTimer *)aTimer;

@end
