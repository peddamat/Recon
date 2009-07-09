//
//  ExpertSettingsViewController.m
//  recon
//
//  Created by Sumanth Peddamatham on 7/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ExpertSettingsViewController.h"


@implementation ExpertSettingsViewController

- (id)init
{
   if (![super initWithNibName:@"ExpertSettingsView"
                        bundle:nil]) {
      return nil;
   }
   [self setTitle:@"ExpertSettings"];
   return self;
}

@end
