//
//  NTLoginItemMgr.m
//  CocoaTechBase
//
//  Created by sgehrman on Sun Jun 17 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NTLoginItemMgr.h"
#import "NTSharedFileListMgr.h"

@implementation NTLoginItemMgr

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE

- (id)init;
{
	self = [super init];
	
	// make sure the pref is in sync
	[[NSUserDefaults standardUserDefaults] setBool:[self isLoginItem:[NTFileDesc descNoResolve:[[NSBundle mainBundle] bundlePath]]] forKey:kLaunchAfterLogin];	

	// register for changes in the pref so we can do our thing, removing or adding the login item
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
															  forKeyPath:[NSString stringWithFormat:@"values.%@", kLaunchAfterLogin]
																 options:NSKeyValueObservingOptionOld
																 context:NULL];
	
	return self;
}

- (void)dealloc;
{
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[NSString stringWithFormat:@"values.%@", kLaunchAfterLogin]];

	[super dealloc];
}

- (BOOL)isLoginItem:(NTFileDesc*)theDesc;
{
	return [[NTSharedFileListMgr sharedInstance] isLoginItem:theDesc];
}

- (void)removeLoginItem:(NTFileDesc*)theDesc
{
	[[NTSharedFileListMgr sharedInstance] removeLoginItem:theDesc];
}

- (void)addLoginItem:(NTFileDesc*)theDesc;
{
	[[NTSharedFileListMgr sharedInstance] addLoginItem:theDesc];
}

- (void)observeValueForKeyPath:(NSString *)key
					  ofObject:(id)object 
                        change:(NSDictionary *)change
                       context:(void *)context;
{
	NTFileDesc* theDesc = [NTFileDesc descNoResolve:[[NSBundle mainBundle] bundlePath]];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kLaunchAfterLogin])
	{
		if (![self isLoginItem:theDesc])
			[self addLoginItem:theDesc];
	}
	else
	{
		if ([self isLoginItem:theDesc])
			[self removeLoginItem:theDesc];
	}	
}

@end

