//
//  NSManagedObjectContext-helper.h
//  recon
//
//  Thanks to: http://cocoawithlove.com/2008/03/core-data-one-line-fetch.html

#import <Cocoa/Cocoa.h>

@interface NSManagedObjectContext (helper)

- (NSArray *)fetchObjectsForEntityName:(NSString *)newEntityName
                         withPredicate:(id)stringOrPredicate, ...;


@end
