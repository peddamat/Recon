//
//  NTSizeCalculatorMgr.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTSizeCalculatorMgr.h"
#import "NTSizeCalculator.h"
#import "NTSizeCalculatorTreeMgr.h"

/* sizecalculator manager
 
 - this holds all the NTSizeCalculator objects created by the client app
 - this uses the treemgr which maintains a tree per volume of requested folders
 
 */

@interface NTSizeCalculatorMgr (Private)
- (void)processIncoming;
@end

@implementation NTSizeCalculatorMgr

@synthesize calculators;
@synthesize pendingAdditions;
@synthesize pendingRemovals;
@synthesize pendingUpdates;
@synthesize sentProcessAfterDelay;
@synthesize sizeCache;

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

- (id)init;
{
	self = [super init];
	
	self.calculators = [NSMutableDictionary dictionary];
	self.pendingAdditions = [NSMutableDictionary dictionary];
	self.pendingRemovals = [NSMutableDictionary dictionary];
	self.pendingUpdates = [NSMutableDictionary dictionary];
	self.sizeCache = [NSMutableDictionary dictionaryWithCapacity:500];
	
	return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	self.calculators = nil;
	self.pendingAdditions = nil;
	self.pendingRemovals = nil;
	self.pendingUpdates = nil;
	self.sizeCache = nil;
	
    [super dealloc];
}

- (void)addCalculator:(NTSizeCalculator*)calculator;
{
	@synchronized(self) {
		[self.pendingAdditions setObject:calculator forKey:[calculator uniqueID]];
	}
	
	[self processIncoming];
}

- (void)removeCalculator:(NTSizeCalculator*)calculator;
{
	@synchronized(self) {
		[self.pendingAdditions removeObjectForKey:[calculator uniqueID]];
		[self.pendingRemovals setObject:calculator forKey:[calculator uniqueID]];
	}
	
	[self processIncoming];
}

@end

@implementation NTSizeCalculatorMgr (TreeNotifications)

- (void)folderSizeUpdated:(NTFileDesc*)folder size:(NTFSSize*)theSize;
{
	@synchronized(self) {
		[self.pendingUpdates setObject:theSize forKey:[folder dictionaryKey]];
	}
	
	[self processIncoming];
}

@end

@implementation NTSizeCalculatorMgr (Private)

- (void)processIncoming;
{
	@synchronized(self) {
		if (!self.sentProcessAfterDelay)
		{			
			self.sentProcessAfterDelay = YES;
			[self performSelectorOnMainThread:@selector(processIncomingAfterDelay) withObject:nil];
		}
	}
}

// called on main thread
- (void)processIncomingAfterDelay;
{
	if (![NSThread isMainThread])
		NSLog(@"-[%@ %@] not main thread", [self className], NSStringFromSelector(_cmd));
	
	NSDictionary* pendingAdditionsCopy=nil;
	NSDictionary* pendingRemovalsCopy=nil;
	NSDictionary* pendingUpdatesCopy=nil;
	
	// make copies protected by synchronized
	@synchronized(self) {
		pendingAdditionsCopy = [NSDictionary dictionaryWithDictionary:self.pendingAdditions];
		pendingRemovalsCopy = [NSDictionary dictionaryWithDictionary:self.pendingRemovals];
		pendingUpdatesCopy = [NSDictionary dictionaryWithDictionary:self.pendingUpdates];
		
		// reset dictionaries back to empty
		[self.pendingAdditions removeAllObjects];
		[self.pendingRemovals removeAllObjects];
		[self.pendingUpdates removeAllObjects];
		
		self.sentProcessAfterDelay = NO;
	}
	
	NSMutableArray* addFolders = [NSMutableArray array];
	NSMutableArray* removedFolders = [NSMutableArray array];
	
	// additions first
	for (NTSizeCalculator* calculator in [pendingAdditionsCopy allValues])
	{			
		NSString* key = [calculator.folder dictionaryKey]; 
		NSMutableDictionary *calculatorsDictionary = [self.calculators objectForKey:key];
		if (calculatorsDictionary.count == 0)
		{
			// first time we encounted this folder, so add to tree
			[addFolders addObject:calculator.folder];
			
			calculatorsDictionary = [NSMutableDictionary dictionary];
			[self.calculators setObject:calculatorsDictionary forKey:key];
		}
		[calculatorsDictionary setObject:calculator forKey:[calculator uniqueID]];
	}
	
	// now do any subtractions
	for (NTSizeCalculator* calculator in [pendingRemovalsCopy allValues])
	{			
		NSString* key = [calculator.folder dictionaryKey]; 
		NSMutableDictionary *calculatorsDictionary = [self.calculators objectForKey:key];
		
		if (calculatorsDictionary)
		{
			[calculatorsDictionary removeObjectForKey:[calculator uniqueID]];
			
			// if 0, remove dictionary so it's back to nil
			if (calculatorsDictionary.count == 0)
			{
				[removedFolders addObject:calculator.folder];
				
				[self.calculators removeObjectForKey:key];
			}
		}
		else
			; // NSLog(@"-[%@ %@] calculatorsDictionary not found?", [self className], NSStringFromSelector(_cmd));
	}
	
	// do updates
	for (NSString* key in [pendingUpdatesCopy allKeys])
	{
		NTFSSize* theSize = [pendingUpdatesCopy objectForKey:key];
		NSMutableDictionary *calculatorsDictionary = [self.calculators objectForKey:key];
		
		// add to the cache
		[self setSize:theSize forKey:key];
		
		for (NTSizeCalculator* calculator in [calculatorsDictionary allValues])
			[calculator setSizeAndNotifyDelegate:theSize];
	}
	
	// add and remove in tree
	[[NTSizeCalculatorTreeMgr sharedInstance] addFolders:addFolders];
	[[NTSizeCalculatorTreeMgr sharedInstance] removeFolders:removedFolders];
}

@end

@implementation NTSizeCalculatorMgr (SizeCache)

- (NTFSSize*)sizeForKey:(NSString*)key;
{
	return [self.sizeCache safeObjectForKey:key];
}

- (void)setSize:(NTFSSize*)size forKey:(NSString*)key;
{
	return [self.sizeCache safeSetObject:size forKey:key];
}

@end

