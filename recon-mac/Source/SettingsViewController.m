//
//  SettingsViewController.m
//  recon
//
//  Created by Sumanth Peddamatham on 8/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SettingsViewController.h"

#import "Host.h"
#import "Port.h"
#import "Profile.h"
#import "Session.h"
#import "OsMatch.h"

#import "NSManagedObjectContext-helper.h"

@implementation SettingsViewController 

@synthesize targetBarSettingsContent;

- (id)init 
{
   if (self = [super init])
   {
      if (![super initWithNibName:@"Settings"
                           bundle:nil]) {
         return nil;
      }
      [self setTitle:@"Settings"];      
   }   
   return self;
}
   
   
- (void)awakeFromNib
{      
   // NSView retains   
   [targetBarSettingsContent retain];   
   [sideBarSettingsContent retain];     
   [workspaceSettingsContent retain];   
   
//   NSPoint point = NSMakePoint(0, 0);
//   [[workspaceSettingsScrollView contentView] scrollToPoint: point];
//   [workspaceSettingsScrollView reflectScrolledClipView: [workspaceSettingsScrollView contentView]];   
   
   NSPoint bottomOfDocument = {0, 9999999};
   bottomOfDocument = [[workspaceSettingsScrollView contentView]
                       constrainScrollPoint:bottomOfDocument];
   [[workspaceSettingsScrollView contentView] scrollToPoint:bottomOfDocument];   
   
   [self performSelector:@selector(expandProfileView) withObject:self afterDelay:0];
}

#pragma mark -

// -------------------------------------------------------------------------------
//	expandProfileView: BEAUTIFIER FUNCTION.  Expand the folders in the Profiles Drawer.
// -------------------------------------------------------------------------------
- (void)expandProfileView
{
   [profilesOutlineView expandItem:nil expandChildren:YES];   
   [profilesTreeController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:0]];
}

// -------------------------------------------------------------------------------
//	addProfile: Add a new profile to the Persistent Store.  User-created profiles
//             are all stored in an NSTreeController-branch titled "User Profiles".
// -------------------------------------------------------------------------------
- (IBAction)addProfile:(id)sender
{
   // Search for a branch titled "User Profiles"
   NSArray *array = [[self managedObjectContext] fetchObjectsForEntityName:@"Profile"
                                                             withPredicate:@"name = 'User Profiles'"];
   Profile *profileParent = [array lastObject];
   
   // If the branch doesn't exist, create it
   if (profileParent == nil)
   {
      profileParent = [NSEntityDescription insertNewObjectForEntityForName:@"Profile" 
                                                    inManagedObjectContext:[self managedObjectContext]]; 
      [profileParent setName:@"User Profiles"];
   }
   
   Profile *profile = nil; 
   
   // Insert a new, uninitialized profile into the Persistent Store
   profile = [NSEntityDescription insertNewObjectForEntityForName:@"Profile" 
                                           inManagedObjectContext:[self managedObjectContext]]; 
   [profile setValue: @"New Profile" forKey: @"name"]; 
   [profile setValue:profileParent forKey:@"parent"];
   
   // Expand the profiles window
   [profilesOutlineView expandItem:nil expandChildren:YES];   
}

// -------------------------------------------------------------------------------
//	deleteProfile: Delete the currently selected profile from the MOC.
//                Prevent the user from deleting folders or default profiles.
// -------------------------------------------------------------------------------
- (IBAction)deleteProfile:(id)sender
{
   // Get selected profile
   Profile *selectedProfile = [[profilesTreeController selectedObjects] lastObject];
   
   NSString *parentName = [selectedProfile valueForKeyPath:@"parent.name"];
   
   // Make sure it's not a Default
   //   if ((parentName == nil) || ([parentName compare:@"Defaults"] == NSOrderedSame)) {
   if ((parentName == nil) || ([parentName isEqualToString:@"Defaults"])) {
      NSRunAlertPanel(@"Recon", @"Sorry, default profiles and profile folders cannot be deleted.",   
                      @"OK", nil, nil);
      
      return;
   }
   else {
      // Delete profile
      [[self managedObjectContext] deleteObject:selectedProfile];
   }
}

#pragma mark -
#pragma mark Sort Descriptors

// -------------------------------------------------------------------------------
//	Sort Descriptors for the various table views
// -------------------------------------------------------------------------------

// http://fadeover.org/blog/archives/13
- (NSArray *)hostSortDescriptor
{
	if(hostSortDescriptor == nil){
		hostSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"ipv4Address" ascending:YES]];
   }
   
	return hostSortDescriptor;
}

- (void)setHostSortDescriptor:(NSArray *)newSortDescriptor
{
	hostSortDescriptor = newSortDescriptor;
}

- (NSArray *)portSortDescriptor
{
	if(portSortDescriptor == nil){
		portSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"number" ascending:YES]];
   }
   
	return portSortDescriptor;
}

- (void)setPortSortDescriptor:(NSArray *)newSortDescriptor
{
	portSortDescriptor = newSortDescriptor;
}

- (NSArray *)profileSortDescriptor
{
	if(profileSortDescriptor == nil){
		profileSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]];
   }
   
	return profileSortDescriptor;
}

- (void)setProfileSortDescriptor:(NSArray *)newSortDescriptor
{
	profileSortDescriptor = newSortDescriptor;
}

- (NSArray *)sessionSortDescriptor
{
	if(sessionSortDescriptor == nil){
		sessionSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO]];
   }
   
	return sessionSortDescriptor;
}

- (void)setSessionSortDescriptor:(NSArray *)newSortDescriptor
{
	sessionSortDescriptor = newSortDescriptor;
}

- (NSArray *)osSortDescriptor
{
	if(osSortDescriptor == nil){
		osSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO]];
   }
   
	return osSortDescriptor;
}

- (void)setOsSortDescriptor:(NSArray *)newSortDescriptor
{
	osSortDescriptor = newSortDescriptor;
}

@end
