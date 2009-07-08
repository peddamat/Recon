//
//  ScanController.h
//  recon
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

@interface SessionController : NSObject {
   
   Session *session;   
   NSString *outputFile;   
   NSString *sessionUUID;
   
   NmapController *nmapController;
}

   @property (readonly) NSString *sessionUUID;

- (void) launchNewSessionWithProfile:(Profile *)profile 
                         withTarget:(NSString *)sessionTarget 
             inManagedObjectContext:(NSManagedObjectContext *)context;

+ (NSString *) stringWithUUID;

@end
