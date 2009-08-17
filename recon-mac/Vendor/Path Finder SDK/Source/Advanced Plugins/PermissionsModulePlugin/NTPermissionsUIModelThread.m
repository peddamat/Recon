//
//  NTPermissionsUIModelThread.m
//  PermissionsModulePlugin
//
//  Created by Steve Gehrman on 1/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTPermissionsUIModelThread.h"
#import "NTPermissionsUIModel.h"
#import "NTPluginConstants.h"

@interface NTPermissionsUIModelThread (Private)
- (NSCellStateValue)buttonState:(NSCellStateValue)state 
				   forAttribute:(NTFileAttributeID)attributeID
						   desc:(NTFileDesc*)desc;

- (void)addPerm:(unsigned)perm match:(unsigned)match result:(NSMutableArray*)result;
- (NSArray*)permissionArrayWithPermissions:(unsigned int)perm;
@end

@interface NTPermissionsUIModelThread (hidden)
- (void)setModel:(NTPermissionsUIModel *)theModel;
@end

static const int kUndefinedState = 2;

@implementation NTPermissionsUIModelThread

@synthesize model;
@synthesize descs;

+ (NTThreadRunner*)thread:(NSArray*)descs
				 delegate:(id<NTThreadRunnerDelegateProtocol>)delegate;
{
    NTPermissionsUIModelThread* param = [[[NTPermissionsUIModelThread alloc] init] autorelease];
    
    [param setDescs:descs];
	
	return [NTThreadRunner thread:param
						 priority:.8
						 delegate:delegate];	
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{	
    self.model = nil;
    self.descs = nil;
    [super dealloc];
}

@end

@implementation NTPermissionsUIModelThread (Private)

- (NSCellStateValue)buttonState:(NSCellStateValue)state 
				   forAttribute:(NTFileAttributeID)attributeID
						   desc:(NTFileDesc*)desc;
{
	if (state != NSMixedState)
	{
		int bbool = NO;
		
		switch (attributeID)
		{
			case kLocked_attributeID:
				bbool = [desc isLocked];
				break;
			case kInvisible_attributeID:
				bbool = [desc isInvisible];
				break;
			case kExtensionHidden_attributeID:
				bbool = [desc isExtensionHidden];
				break;
			case kStationeryPad_attributeID:
				bbool = [desc isStationery];
				break;
			case kHasBundle_attributeID:
				bbool = [desc isStationery];
				break;
			case kAlias_attributeID:
				bbool = [desc isStationery];
				break;
			case kCustomIcon_attributeID:
				bbool = [desc isStationery];
				break;
				
			case kOnDesktop_attributeID:
			case kInited_attributeID:
			case kNameLocked_attributeID:
			case kLabel_attributeID:
			case kLength_attributeID:
			case kType_attributeID:
			case kCreator_attributeID:
			case kAttributeModificationDate_attributeID:
			case kModificationDate_attributeID:
			case kCreationDate_attributeID:
			case kOwner_attributeID:
			case kGroup_attributeID:
			case kPermissions_attributeID:
			case kStickyBit_attributeID:
			case kSpotlightComments_attributeID:
			default:
				NSLog(@"-[%@ %@] shouldn't get here!", [self className], NSStringFromSelector(_cmd));
				break;
		}
		
		NSCellStateValue newState = (bbool ? NSOnState : NSOffState);
		
		if (state == kUndefinedState)
			state = newState;
		else if (state != newState)
			state = NSMixedState;
	}
	
	return state;
}

- (void)addPerm:(unsigned)perm match:(unsigned)match result:(NSMutableArray*)result;
{
	if (perm & match)
		[result addObject:[NSNumber numberWithUnsignedInt:match]];
}

// pass [[self desc] posixPermissions];
- (NSArray*)permissionArrayWithPermissions:(unsigned int)perm;
{
	NSMutableArray* result = [NSMutableArray array];
	
	[self addPerm:perm match:S_IRUSR result:result];
	[self addPerm:perm match:S_IWUSR result:result];
	[self addPerm:perm match:S_IXUSR result:result];
	
	[self addPerm:perm match:S_IRGRP result:result];
	[self addPerm:perm match:S_IWGRP result:result];
	[self addPerm:perm match:S_IXGRP result:result];
	
	[self addPerm:perm match:S_IROTH result:result];
	[self addPerm:perm match:S_IWOTH result:result];
	[self addPerm:perm match:S_IXOTH result:result];
	
	return [NSArray arrayWithArray:result];
}

@end

@implementation NTPermissionsUIModelThread (Thread)

// override from the base class
- (BOOL)doThreadProc;
{
	NSArray *theDescs = [self descs];
	if ([theDescs count])
	{
		NTFileDesc* desc;
		BOOL usersMatch=YES;
		NTNameAndID *user = nil;
		BOOL groupsMatch=YES;
		NTNameAndID *group = nil;
		unsigned modeBits=0;
		BOOL modeBitsMatch = YES;
		BOOL locked=NO;  // just want to know if any item is locked
		NSMutableArray* selectedPermissions = nil;

		NTPermissionsUIModel* theModel = [NTPermissionsUIModel model];		
		
		[theModel setWritable:YES];  // set to NO if we find an desc not writable
		[theModel setIsFile:YES];  // set to NO if we find an desc is a dir
		[theModel setIsVolume:YES];  // set to NO if we find an desc is a dir
		
		// loop on theDescs
		for (desc in theDescs)
		{			
			// is writeable
			if (![desc isWritable])
				[theModel setWritable:NO];

			if ([theModel isFile])
			{
				if ([desc isDirectory])
					[theModel setIsFile:NO];
			}

			if ([theModel isVolume])
			{
				if (![desc isVolume])
					[theModel setIsVolume:NO];
			}
			
			// just need to know if any item is locked
			if (!locked)
				locked = [desc isLocked];
			
			NTNameAndID* tmp;
			
			// handle user
			if (usersMatch)
			{
				tmp = [[NTUsersAndGroups sharedInstance] userWithID:[desc ownerID]];
				if (!user)
					user = tmp;
				else if (![user isEqual:tmp])
					usersMatch = NO;
			}
			
			// handle group
			if (groupsMatch)
			{
				tmp = [[NTUsersAndGroups sharedInstance] groupWithID:[desc groupID]];
				if (!group)
					group = tmp;
				else if (![group isEqual:tmp])
					groupsMatch = NO;
			}

			// handle modeBits
			if (modeBitsMatch)
			{
				if (!modeBits)
					modeBits = [desc posixFileMode];
				else if (modeBits != [desc posixFileMode])
					modeBitsMatch = NO;
			}
			
			// get minimal matching permissions
			NSArray* permArray = [self permissionArrayWithPermissions:[desc posixPermissions]];
			if (!selectedPermissions)
				selectedPermissions = [NSMutableArray arrayWithArray:permArray];
			else
			{
				// remove any permissions not found in new array
				NSEnumerator *e = [selectedPermissions reverseObjectEnumerator];  // must go in reverse since we delete
				id obj;
				
				while (obj = [e nextObject])
				{
					if (![permArray containsObject:obj])
						[selectedPermissions removeObject:obj];
				}
			}
		}

		[theModel setLocked:locked];

		desc = [theDescs objectAtIndex:0];
		[theModel setMultipleSelection:([theDescs count] > 1)];
		if (![theModel multipleSelection])
			;
		
		if (usersMatch)
			[theModel setUser:user];
		if (groupsMatch)
			[theModel setGroup:group];
		
		// convert permissions to selection array
		[theModel setSelectedPermissions:selectedPermissions];
		
		if (modeBitsMatch)
		{
			[theModel setPermissionString:[NTFileDesc permissionsTextForModeBits:modeBits includeOctal:NO]];
			
			[theModel setPermissionOctalString:[NTFileDesc permissionOctalStringForModeBits:modeBits]];
		}
		
		// set our result
		self.model = theModel;
	}
	
	return ![[self helper] killed];	
}

@end
