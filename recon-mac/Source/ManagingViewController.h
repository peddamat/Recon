//
//  ManagingViewController.h
//  recon
//
//  Created by Sumanth Peddamatham on 7/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ManagingViewController : NSViewController {
   NSManagedObjectContext *managedObjectContext;
}
@property (retain) NSManagedObjectContext *managedObjectContext;
@end
