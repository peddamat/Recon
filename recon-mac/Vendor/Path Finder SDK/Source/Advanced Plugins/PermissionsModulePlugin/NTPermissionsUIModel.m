//
//  NTPermissionsUIModel.m
//  PermissionsModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTPermissionsUIModel.h"

@interface NTPermissionsUIModel (Private)
- (NSArray *)keyPaths;

+ (NSArray*)defaultPermissions;
@end

@implementation NTPermissionsUIModel

@synthesize initialized;
@synthesize permissions;
@synthesize selectedPermissions;
@synthesize permissionString;
@synthesize permissionOctalString;
@synthesize groups;
@synthesize group;
@synthesize users;
@synthesize user;
@synthesize observed;
@synthesize writable;
@synthesize isFile;
@synthesize isVolume;
@synthesize multipleSelection;
@synthesize locked;
@synthesize ignoreOwnership;

+ (NTPermissionsUIModel*)model;
{
	NTPermissionsUIModel* result = [[NTPermissionsUIModel alloc] init];
					
	[result setPermissionString:[NTFileDesc permissionsTextForModeBits:0 includeOctal:NO]];

	[result setGroups:[[NTUsersAndGroups sharedInstance] groups]];
	[result setUsers:[[NTUsersAndGroups sharedInstance] users]];
	[result setPermissions:[self defaultPermissions]];

	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	self.permissions = nil;
    self.selectedPermissions = nil;
    self.permissionString = nil;
    self.permissionOctalString = nil;
    self.groups = nil;
    self.group = nil;
    self.users = nil;
    self.user = nil;
	[super dealloc];
}

- (unsigned)selectedPermissionBits;
{
	unsigned result = 0;
	NSEnumerator* enumerator = [[self selectedPermissions] objectEnumerator];
	NSNumber* perm;
	
	while (perm = [enumerator nextObject])
		result |= [perm unsignedIntValue];
	
	return result;
}

- (void)startObserving:(id)observer;
{
	[self setObserved:YES];
	
	NSEnumerator *e = [[self keyPaths] objectEnumerator];
	NSString *thisKey;
	
	while (thisKey = [e nextObject])
	{
		[self addObserver:observer
			   forKeyPath:thisKey
				  options:NSKeyValueObservingOptionOld
				  context:NULL];
    }
}

- (void)stopObserving:(id)observer
{
	if ([self observed])
	{
		[self setObserved:NO];
		
		NSEnumerator *e = [[self keyPaths] objectEnumerator];
		NSString *thisKey;
		
		while (thisKey = [e nextObject])
			[self removeObserver:observer forKeyPath:thisKey];
	}
}

- (unsigned)permissionBitsFromOctalString;
{
	unsigned result = 0xFFFFFFFF;
	NSString* str = [self permissionOctalString];
	
	// must be 3 characters long
	if ([str length] == 3)
	{
		unsigned num = [str intValue];
		
		result = (num / 100) << 6;  // octets
		num = num % 100;
		result |= (num / 10) << 3;  // octets
		num = num % 10;
		result |= num;
	}
	
	return result;
}

@end

@implementation NTPermissionsUIModel (Private)

- (NSArray *)keyPaths
{
    NSArray *result = [NSArray arrayWithObjects:
        @"permissions",
        @"selectedPermissions",
        @"permissionString",
        @"permissionOctalString",
        @"groups",
        @"group",
        @"users",
        @"user",
        @"writable",
        @"isFile",
        @"multipleSelection",
        @"locked",
		@"ignoreOwnership",
        nil];
	
    return result;
}

+ (NSArray*)defaultPermissions;
{
	static NSArray *shared = nil;
	
	if (!shared)
	{
		NSString* readTitle = [NTLocalizedString localize:@"Read" table:@"Get Info"]; 
		NSString* writeTitle = [NTLocalizedString localize:@"Write" table:@"Get Info"]; 
		NSString* executeTitle = [NTLocalizedString localize:@"Execute" table:@"Get Info"]; 
		
		NSMutableArray* result = [NSMutableArray array];
		
		[result addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:S_IRUSR], @"value", readTitle, @"title", nil]];
		[result addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:S_IWUSR], @"value", writeTitle, @"title", nil]];
		[result addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:S_IXUSR], @"value", executeTitle, @"title", nil]];

		[result addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:S_IRGRP], @"value", readTitle, @"title", nil]];
		[result addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:S_IWGRP], @"value", writeTitle, @"title", nil]];
		[result addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:S_IXGRP], @"value", executeTitle, @"title", nil]];

		[result addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:S_IROTH], @"value", readTitle, @"title", nil]];
		[result addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:S_IWOTH], @"value", writeTitle, @"title", nil]];
		[result addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:S_IXOTH], @"value", executeTitle, @"title", nil]];
				
		shared = [[NSArray alloc] initWithArray:result];
	}
	
	return shared;
}

@end
