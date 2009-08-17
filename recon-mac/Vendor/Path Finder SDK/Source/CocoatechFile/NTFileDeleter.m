//
//  NTFileDeleter.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Tue May 21 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import "NTFileDeleter.h"
#import "NTSecureDelete.h"
#import "NTFileModifier.h"

@interface NTFileDeleter (Private)
- (id<NTFileDeleterDelegateProtocol>)delegate;
- (void)setDelegate:(id<NTFileDeleterDelegateProtocol>)theDelegate;

- (BOOL)doDeleteFile:(NTFileDesc*)desc itemSkipped:(BOOL*)outItemSkipped;
- (BOOL)doDeleteDirectory:(NTFileDesc*)desc itemSkipped:(BOOL*)outItemSkipped;

- (NTSecureDelete *)secureDelete;
- (void)setSecureDelete:(NTSecureDelete *)theSecureDelete;

- (NTFileDesc*)setWritePermissions:(NTFileDesc*)desc;
- (NTFileDesc*)unlockDesc:(NTFileDesc*)desc;
@end

@implementation NTFileDeleter

- (void)dealloc;
{
	if ([self delegate])
		[NSException raise:@"must call clear delegate" format:@"%@", NSStringFromClass([self class])];

	[self setSecureDelete:nil];
	
    [super dealloc];
}

- (void)clearDelegate;
{
	[self setDelegate:nil];
}

+ (NTFileDeleter*)deleter:(id<NTFileDeleterDelegateProtocol>)delegate
	securityLevel:(NTDeleteSecurityLevel)securityLevel;
{
	NTFileDeleter* result = [[NTFileDeleter alloc] init];
	
	// only set if not kNormalDelete
	if (securityLevel != kNormalDelete)
		[result setSecureDelete:[NTSecureDelete secureDelete:securityLevel]];

	[result setDelegate:delegate]; // don't retain

	return [result autorelease];
}

- (void)deleteDesc:(NTFileDesc*)desc;
{
    if (![desc isVolume])
    {        		
		BOOL itemSkipped = NO;
		
        if ([desc isFile])
            [self doDeleteFile:desc itemSkipped:&itemSkipped];
        else
            [self doDeleteDirectory:desc itemSkipped:&itemSkipped];  // recursive function that deletes all sub items
    }
}

@end

@implementation NTFileDeleter (Private)

//---------------------------------------------------------- 
//  secureDelete 
//---------------------------------------------------------- 
- (NTSecureDelete *)secureDelete
{
    return mSecureDelete; 
}

- (void)setSecureDelete:(NTSecureDelete *)theSecureDelete
{
    if (mSecureDelete != theSecureDelete) {
        [mSecureDelete release];
        mSecureDelete = [theSecureDelete retain];
    }
}

- (BOOL)doDeleteFile:(NTFileDesc*)desc
	itemSkipped:(BOOL*)outItemSkipped;
{
    BOOL continueDeleting = YES;
    
    NS_DURING;
    {
        // make sure file is not locked
        desc = [self unlockDesc:desc];
        
		continueDeleting = [[self delegate] deleter:self deleteProgress:desc];
		if (continueDeleting)
		{
			OSStatus err;
			
			if ([self secureDelete])
				err = [[self secureDelete] deleteFile:[desc fileSystemPath]];
			else
				err = FSDeleteObject([desc FSRefPtr]);
			
			if (err != noErr)
			{
				continueDeleting = [[self delegate] deleter:self displayErrorAtPath:desc error:err];
				
				*outItemSkipped = YES;
			}
		}
	}
	NS_HANDLER
		continueDeleting = NO;
	NS_ENDHANDLER;
	
	return continueDeleting;
}

- (BOOL)doDeleteDirectory:(NTFileDesc*)desc 
			  itemSkipped:(BOOL*)outItemSkipped;
{
	BOOL continueDeleting = YES;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NS_DURING;
	{		
		// make sure directory is unlocked and writable first
		desc = [self unlockDesc:desc];
		desc = [self setWritePermissions:desc];
		
		OSStatus err=noErr;
		
		// test if directory is writable, if not, don't bother recursively walking the contents
		if (![desc isWritable])
			err = wrPermErr; // no write perms
		else
		{
			// delete the directories contents
			NSArray* contents = [desc directoryContentsForDelete];
			NTFileDesc *itemDesc;
			for (itemDesc in contents)
			{		
				if ([itemDesc isFile])
					continueDeleting = [self doDeleteFile:itemDesc itemSkipped:outItemSkipped];
				else
					continueDeleting = [self doDeleteDirectory:itemDesc itemSkipped:outItemSkipped];
				
				if (!continueDeleting)
					break;
			}
			
			// now delete the directory
			if (continueDeleting)
			{
				continueDeleting = [[self delegate] deleter:self deleteProgress:desc];
				
				if (continueDeleting)
				{
					// directory should be empty when it gets here, so FSDeleteObject should work					
					if (!(*outItemSkipped))
						err = FSDeleteObject([desc FSRefPtr]);
				}
			}
		}
		
		if (err != noErr)
		{
			continueDeleting = [[self delegate] deleter:self displayErrorAtPath:desc error:err];
			
			*outItemSkipped = YES;
		}
	}
	NS_HANDLER
		continueDeleting = NO;
	NS_ENDHANDLER;	
	
	[pool release];
    
    return continueDeleting;
}

// directories must be writable before trying to delete their contents
- (NTFileDesc*)setWritePermissions:(NTFileDesc*)desc;
{
	NTFileDesc* result = desc;
    unsigned long perm = [desc posixPermissions];

    if ((perm & S_IWUSR) == 0)
    {
        perm |= S_IWUSR;

        [NTFileModifier setPermissions:perm desc:desc];
		
		result = [desc newDesc];
    }
	
	return result;
}

// items must be unlocked before deleting
- (NTFileDesc*)unlockDesc:(NTFileDesc*)desc;
{
	NTFileDesc* result = desc;
	
    if ([desc isLocked])
	{
        [NTFileModifier setLock:NO desc:desc];
		
		result = [desc newDesc];
	}
	
	return result;
}

//---------------------------------------------------------- 
//  delegate 
//---------------------------------------------------------- 
- (id<NTFileDeleterDelegateProtocol>)delegate
{
    return mv_delegate; 
}

- (void)setDelegate:(id<NTFileDeleterDelegateProtocol>)theDelegate
{
    if (mv_delegate != theDelegate) {
        mv_delegate = theDelegate; // not retained
    }
}

@end
