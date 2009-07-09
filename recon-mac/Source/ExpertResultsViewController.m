//
//  ExpertResultsViewController.m
//  recon
//
//  Created by Sumanth Peddamatham on 7/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ExpertResultsViewController.h"


@implementation ExpertResultsViewController

- (id)init
{
   if (![super initWithNibName:@"ExpertResultsView"
                        bundle:nil]) {
      return nil;
   }
   [self setTitle:@"ExpertResults"];
   return self;
}

@end
