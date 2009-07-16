//
//  NmapController.h
//  recon
//
//  Created by Sumanth Peddamatham on 7/1/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Session;

@interface NmapController : NSObject {
   
	NSTask *task;   
   
	NSMutableData *standardOutput;
	NSMutableData *standardError;
	NSString *outputString;
	NSString *errorString; 
   
   NSString *outputFilePath;
   
   BOOL hasRun;
   
}

@property(readonly) BOOL hasRun;

- (id) initWithNmapBinary:(NSString *)nmapBinary 
                 withArgs:(NSArray *)nmapArgs 
       withOutputFilePath:(NSString *)outputFilePath;

- (BOOL) isRunning;
- (void) startScan;
- (void) abortScan;

@end
