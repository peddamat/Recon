//
//  SessionController.h
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
   
   BOOL hasRun;   
   BOOL isRunning;
   BOOL deleteAfterAbort;
   
   NSArray *nmapArguments;   
   NmapController *nmapController;
   
   NSTimer *resultsTimer;
   XMLController *xmlController;
   
   // The lock is used to synchronize session aborts
   NSString *lock;
}

@property (readonly, assign) BOOL hasRun;
@property (readonly, assign) BOOL isRunning;
@property (readwrite, retain) Session *session;
@property (readonly, retain) NSString *sessionUUID;

- (Session *)initWithProfile:(Profile *)profile 
                   withTarget:(NSString *)sessionTarget     
      inManagedObjectContext:(NSManagedObjectContext *)context;

- (Session *)initWithSession:(Session *)existingSession;

- (Profile *)copyProfile:(Profile *)profile;
- (BOOL)createSessionDirectory:(NSString *)uuid;

- (void)initNmapController;
- (void)startScan;
- (void)abortScan;
- (void)deleteSession;
- (void)readProgress:(NSTimer *)aTimer;

+ (NSString *) stringWithUUID;

@end
