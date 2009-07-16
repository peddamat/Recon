//
//  ArgumentListGenerator.h
//  recon
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
   
}

+ (NSArray *) convertProfileToArgs:(Profile *)profile 
                        withTarget:(NSString *)target 
                     withOutputFile:(NSString*)nmapOutput;

@end
