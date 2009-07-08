//
//  NmapController.h
//  nmapX-coredata
//
//  Created by Sumanth Peddamatham on 7/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import <SecurityFoundation/SFAuthorization.h>

@class Session;

@interface NmapController : NSObject {
   
//	(SFAuthorization *) authorization; 
	NSTask *task;   
   
	NSMutableData *standardOutput;
	NSMutableData *standardError;
	NSString *outputString;
	NSString *errorString;   
}

- (void) launchScan:(NSString *)nmapBinary withArgs:(NSArray *)args withOutputFile:(NSString *)outputFile;
- (void) abortScan;
@end
