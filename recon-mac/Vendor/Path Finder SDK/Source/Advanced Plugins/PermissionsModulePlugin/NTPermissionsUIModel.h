//
//  NTPermissionsUIModel.h
//  PermissionsModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTPermissionsUIModel : NSObject 
{
	BOOL initialized;

	NSArray* permissions;
	NSArray* selectedPermissions;
	
	NSString* permissionString;
	NSString* permissionOctalString; // 755
	
	NSArray* groups;
	NTNameAndID* group;

	NSArray* users;
	NTNameAndID* user;
	
	BOOL observed;  // YES if startObserving is called
	
	// used for enabling/disabling
	BOOL writable;
	BOOL isFile;
	BOOL isVolume;
	BOOL multipleSelection;	
	BOOL locked;	
	BOOL ignoreOwnership;
}

@property (assign) BOOL initialized;
@property (retain) NSArray* permissions;
@property (retain) NSArray* selectedPermissions;
@property (retain) NSString* permissionString;
@property (retain) NSString* permissionOctalString;
@property (retain) NSArray* groups;
@property (retain) NTNameAndID* group;
@property (retain) NSArray* users;
@property (retain) NTNameAndID* user;
@property (assign) BOOL observed;
@property (assign) BOOL writable;
@property (assign) BOOL isFile;
@property (assign) BOOL isVolume;
@property (assign) BOOL multipleSelection;
@property (assign) BOOL locked;
@property (assign) BOOL ignoreOwnership;

+ (NTPermissionsUIModel*)model;

- (void)startObserving:(id)observer;
- (void)stopObserving:(id)observer;

- (unsigned)selectedPermissionBits;
- (unsigned)permissionBitsFromOctalString;  // 0xFFFFFFFF returned if not valid
@end
