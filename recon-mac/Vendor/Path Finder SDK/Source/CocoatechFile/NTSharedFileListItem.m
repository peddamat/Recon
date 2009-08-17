//
//  NTSharedFileListItem.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 4/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTSharedFileListItem.h"
#import "NSImage-CocoatechFile.h"
#import "NTVolumeMgrState.h"

@interface NTSharedFileListItem ()
@property (retain) id cachedURL;
@property (retain) id cachedResolvedURL;
@property (retain) NTVolumeMgrState* volumeMgrState;
@end

@interface NTSharedFileListItem (Private)
- (void)updateURL:(BOOL)theResolve;
- (void)updateCache;
@end

@implementation NTSharedFileListItem

@synthesize itemRef;
@synthesize name;
@synthesize uniqueID;
@synthesize cachedURL;
@synthesize cachedResolvedURL;
@synthesize volumeMgrState, networkStateID;

+ (NTSharedFileListItem*)item:(LSSharedFileListItemRef)theItem;
{
	NTSharedFileListItem* result = [[NTSharedFileListItem alloc] init];
	
	result.itemRef = (LSSharedFileListItemRef)CFRetain(theItem);
	[result updateCache];

	return [result autorelease];
}

- (void)dealloc;
{
	if (self.itemRef)
		CFRelease(self.itemRef);
	
	self.name = nil;
	self.uniqueID = nil;
	self.cachedURL = nil;
    self.cachedResolvedURL = nil;
	self.volumeMgrState = nil;
	
	[super dealloc];
}

// mounts shared volume if a server, returns URL
- (NSURL*)resolvedURL;
{
	[self updateCache];
	
	if (!self.cachedResolvedURL)
		[self updateURL:YES];
	
	// set to NSNull if not found
	if (![self.cachedResolvedURL isKindOfClass:[NSURL class]])
		return nil;
	
	return self.cachedResolvedURL;
}

- (NSURL*)url;  // returns nil if not resolvable without UI
{
	[self updateCache];

	if (!self.cachedURL)
		[self updateURL:NO];
	
	// set to NSNull if not found
	if (![self.cachedURL isKindOfClass:[NSURL class]])
		return nil;
	
	return self.cachedURL;
}

// overridden to get lazily
- (NSString*)name;
{
	if (!name)
	{		
		CFStringRef cfString = LSSharedFileListItemCopyDisplayName(self.itemRef);
		if (cfString)
		{
			// make a copy and autorelease
			self.name = [NSString stringWithString:(NSString*)cfString];
			CFRelease(cfString);  // docs say must release
		}
	}
	
	return name;
}

- (NSImage*)iconWithSize:(int)theSize;
{
	NSImage* result=nil;
	
	IconRef iconRef = LSSharedFileListItemCopyIconRef(self.itemRef);
	if (iconRef)
	{
		// make a copy and autorelease
		result = [NSImage iconRef:iconRef toImage:theSize];
		ReleaseIconRef(iconRef);  // docs say must release
	}
	
	return result;
}

- (NSNumber*)uniqueID;
{
	if (!uniqueID)
	{		
		UInt32 uniqueInt = LSSharedFileListItemGetID(self.itemRef);

		self.uniqueID = [NSNumber numberWithUnsignedInt:uniqueInt];
	}
	
	return uniqueID;
}

@end

@implementation NTSharedFileListItem (Private)

- (void)updateCache;
{
	BOOL dumpCache = NO;
	
	if (self.volumeMgrState)
	{
		if ([self.volumeMgrState changed])
		{
			self.volumeMgrState = nil;
			dumpCache = YES;
		}
	}
	
	if (self.networkStateID != [[NTSCPrefsListener sharedInstance] networkStateID])
		dumpCache = YES;

	if (dumpCache)
	{
		self.cachedResolvedURL = nil;
		self.cachedURL = nil;
	}	
	
	self.networkStateID = [[NTSCPrefsListener sharedInstance] networkStateID];

	if (!self.volumeMgrState)
		self.volumeMgrState = [NTVolumeMgrState state];
}

- (NSString*)description;
{
	return [NSString stringWithFormat:@"name: %@, id: %@, url: %@", self.name, [self.uniqueID description], [self.url description]];
}

- (void)updateURL:(BOOL)theResolve;
{	
	CFURLRef cfURL=nil;
	OSStatus status = LSSharedFileListItemResolve(self.itemRef,
												  theResolve ? 0 : kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes,
												  &cfURL,
												  nil);  // asking for the FSRef was failing for files! removed it
	if (status == noErr)
	{
		// make a copy and autorelease
		NSURL* result = [[(id)cfURL copy] autorelease];
		CFRelease(cfURL);

		self.cachedResolvedURL = result;
		self.cachedURL = result;
	}
	else
	{
		// set to NSNull if nil to avoid repeating the query of this url
		self.cachedURL = [NSNull null];
		if (theResolve)
			self.cachedResolvedURL = [NSNull null];
	}
}

- (NSUInteger)hash;
{
	return [self.uniqueID hash];
}

- (BOOL)isEqual:(NTSharedFileListItem*)rightObject
{
	return [self.uniqueID isEqual:rightObject.uniqueID];
}

@end
