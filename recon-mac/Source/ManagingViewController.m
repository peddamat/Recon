//
//  ManagingViewController.m
//  recon
//
//  Created by Sumanth Peddamatham on 7/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ManagingViewController.h"

@implementation ManagingViewController
@synthesize managedObjectContext;

- (void)dealloc
{
   [managedObjectContext release];
   [super dealloc];
}
@end