// 
//  Session.m
//  recon
//
//  Created by Sumanth Peddamatham on 7/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Session.h"

#import "Host.h"
#import "Profile.h"

@implementation Session 

@dynamic nmapOutputStdout;
@dynamic target;
@dynamic nmapOutputXml;
@dynamic status;
@dynamic nmapOutputStderr;
@dynamic hostsDown;
@dynamic hostsUp;
@dynamic UUID;
@dynamic progress;
@dynamic date;
@dynamic hostsTotal;
@dynamic hosts;
@dynamic profile;


- (NSNumber *)nameForSelectedProfile
{
   return [[self profile] name];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
   if ([key isEqualToString:@"nameForSelectedProfile"])
      return [NSSet setWithObject:@"profile"];
   else
      return [super keyPathsForValuesAffectingValueForKey:key];
}

// The above magic is from: http://lists.apple.com/archives/Cocoa-dev/2009/Mar/msg01369.html

// Appended below for posterity's sake...

//'NSInternalInconsistencyException', reason: 'Cannot remove an observer
//<Observer 0x10ac00> for the key path "targetPhoto.name" from
//<NSMyArrayController 0x1099d0>, most likely because the value for the
//key "targetPhoto" has changed without an appropriate KVO notification
//being sent. Check the KVO-compliance of the NSMyArrayController class.'
//
//
//That is indeed a real problem and one which can take a lot of time from you. In some cases the scenario really is what the message above is saying. Other times, I think, its something else, or a bug. Re the former, I had a simple app that was getting that problem but which looked fine to me. I showed the code to a bright young man on this mailing list named Hamish Allen and he immediately saw the problem and suggested a fix, which worked perfectly. (See footnote.) To this day, I can't say I completely understand why his fix worked.
//
//I had the same problem in a much more complex app. It was a sort of master-slave display of models and their specific products. If I changed the model for a product I got the error. I discovered that the fields in the product list which actually belonged to the model were causing the problem. For example, in the product list, I showed the product category name via this binding [self.]model.category.name. In the end I hacked it to work by changing the binding to selectedmodel.category.name.
//
//I shudder to think of the number of hours I spent trying to ensure KVO compliance and to really understand this problem.
//
//Your best bet might be to throw yourself at the feet of the talented Mr Allen -- or perhaps you can gain his skills yourself. I've pasted below an excerpt from his masterful email -- maybe you can glean something useful from it.
//
//Good luck,
//
//
//Steve
//
//
//
//
//from Hamish Allen
//
//
//"Cannot remove an observer <NSTableBinder 0x166d00> for the key path
//"contributionForSelectedDecisionValue.degree" from <Alternative
//0x1a90a0>, most likely because the value for the key
//"contributionForSelectedDecisionValue" has changed without an
//appropriate KVO notification being sent. Check the KVO-compliance of
//the Alternative class."
//
//The problem there was pretty much exactly as the error message
//describes: the Contribution in question is being dynamically selected
//within the method contributionForSelectedDecisionValue, and said
//method is free to return a different object than the one it returned
//last time it was called, without
//willChangeValueForKey:@"contributionForSelectedDecisionValue" having
//been called in the interim.
//
//
//This is confirmed by changing the table column binding from
//"contributionForSelectedDecisionValue.degree' to
//'degreeForContributionForSelectedDecisionValue' and writing the
//following code:
//
//
//- (NSNumber *)degreeForContributionForSelectedDecisionValue
//{
//return [[self contributionForSelectedDecisionValue] degree];
//}
//
//
//+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
//{
//if ([key isEqualToString:@"degreeForContributionForSelectedDecisionValue"])
//return [NSSet setWithObject:@"contributionForSelectedDecisionValue"];
//else
//return [super keyPathsForValuesAffectingValueForKey:key];
//}
//
//
//No exception is thrown with this new binding.

@end
