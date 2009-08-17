//
//  ArgumentListGenerator.h
//  Recon
//
//  Created by Sumanth Peddamatham on 6/30/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//
//  Read nmap arguments from managedObject.

//  Read current profile name from interface
//  Search managedObjectContext for Profile entity matching current profile
//  Convert argument array into nmap switch array
//
//  http://www.cocoadevcentral.com/articles/000080.php

#import <Cocoa/Cocoa.h>

@class Profile;

@interface ArgumentListGenerator : NSObject {

   NSDictionary *nmapArgsBool;   
   NSDictionary *nmapArgsString;
   
   // Dictionary for reverse lookups
   NSDictionary *nmapArgsBoolReverse;   
   NSDictionary *nmapArgsStringReverse;   
   
   NSDictionary *nmapArgsTcpString;
   NSDictionary *nmapArgsNonTcpString;
   NSDictionary *nmapArgsTimingString;

   NSDictionary *nmapArgsTcpStringReverse;
   NSDictionary *nmapArgsNonTcpStringReverse;
   NSDictionary *nmapArgsTimingStringReverse;   
}

@property (readwrite, assign) NSDictionary *nmapArgsBool;
@property (readwrite, assign) NSDictionary *nmapArgsString;

@property (readwrite, assign) NSDictionary *nmapArgsBoolReverse;
@property (readwrite, assign) NSDictionary *nmapArgsStringReverse;

@property (readwrite, assign) NSDictionary *nmapArgsTcpString;
@property (readwrite, assign) NSDictionary *nmapArgsNonTcpString;
@property (readwrite, assign) NSDictionary *nmapArgsTimingString;

@property (readwrite, assign) NSDictionary *nmapArgsTcpStringReverse;
@property (readwrite, assign) NSDictionary *nmapArgsNonTcpStringReverse;
@property (readwrite, assign) NSDictionary *nmapArgsTimingStringReverse;

- (NSArray *) convertProfileToArgs:(Profile *)profile 
                        withTarget:(NSString *)target 
                     withOutputFile:(NSString*)nmapOutput;

- (BOOL)areFlagsValid:(NSArray *)argArray;
- (void)populateProfile:(Profile *)profile withArgString:(NSArray *)argArray;

@end
