//
//  NmapController.h
//  recon
//
//  Created by Sumanth Peddamatham on 7/1/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import <SecurityFoundation/SFAuthorization.h>

@class Session;

@interface NmapController : NSObject {
   
//	(SFAuthorization *) authorization; 
	NSTask *task;   
   
	NSMutableData *standardOutput;
	NSMutableData *standardError;   
   NSString *outputFilePath;
   
   BOOL isRunning;
}

- (id) initWithNmapBinary:(NSString *)nmapBinary 
                 withArgs:(NSArray *)nmapArgs 
       withOutputFilePath:(NSString *)outputFilePath;
- (void) startScan;
- (void) abortScan;
@end
