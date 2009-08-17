//
//  NTLabelsModel.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 6/21/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTLabelsModel.h"
#import "NTLabelColor.h"
#import "NTLabelColorMgr.h"

@interface NTLabelsModel (hidden)
- (void)setDictionary:(NSMutableDictionary *)theDictionary;
- (void)setBuildID:(unsigned)theBuildID;
@end

@interface NTLabelsModel (Private)
- (NSString*)keyForLabel:(unsigned)label;
- (void)setDefaultValues;

- (BOOL)saveInProgress;
- (void)setSaveInProgress:(BOOL)flag;

- (void)saveToPreferences;
- (void)loadFromPreferences;

- (void)startObserving;
- (void)stopObserving;
- (void)startObservingObject:(id)thisObject;
- (void)stopObservingObject:(id)thisObject;

@end

#define kLabelsModelKey @"kLabelsModelKey"

@implementation NTLabelsModel

@synthesize gradients;

+ (NTLabelsModel*)model;
{
	NTLabelsModel* result = [[NTLabelsModel alloc] init];
	
	return [result autorelease];
}

- (id)init;
{
	self = [super init];

	[self setDictionary:[NSMutableDictionary dictionary]];
	self.gradients = [NSMutableDictionary dictionary];
	
	[self setDefaultValues];
	[self loadFromPreferences];
	
	[self startObserving];
	
    return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	[self stopObserving];
	
	[self setDictionary:nil];
	self.gradients = nil;
	
    [super dealloc];
}

- (unsigned)count;
{
	return [[self dictionary] count];
}

- (NSColor*)color:(int)label;
{
	return [[[self dictionary] objectForKey:[self keyForLabel:label]] color];
}

- (NTGradientDraw*)gradient:(int)label;
{
	NTGradientDraw* result = [[self gradients] objectForKey:[self keyForLabel:label]];
	
	if (!result)
	{
		NSColor* color = [self color:label];
		result = [NTGradientDraw gradientWithStartColor:[color lighterColor:.3] endColor:[color lighterColor:.65]];
		[self.gradients setObject:result forKey:[self keyForLabel:label]];
	}
	
	return result;
}

// labels are 1-7, 0 is none and returns nil
- (NSString*)name:(int)label;
{
	return [[[self dictionary] objectForKey:[self keyForLabel:label]] name];
}

//---------------------------------------------------------- 
//  dictionary 
//---------------------------------------------------------- 
- (NSMutableDictionary *)dictionary
{
    return mDictionary; 
}

- (void)setDictionary:(NSMutableDictionary *)theDictionary
{
    if (mDictionary != theDictionary) {
        [mDictionary release];
        mDictionary = [theDictionary retain];
    }
}

//---------------------------------------------------------- 
//  buildID 
//---------------------------------------------------------- 
- (unsigned)buildID
{
    return mBuildID+1; // adding one so it's never zero
}

- (void)setBuildID:(unsigned)theBuildID
{
    mBuildID = theBuildID;
}

- (void)restoreDefaults;
{
	[self stopObserving];
	[self setDefaultValues];
	[self startObserving];
	
	[self saveToPreferences];
}

@end

@implementation NTLabelsModel (Private)

- (void)setDefaultValues;
{
	[[self dictionary] setObject:[NTLabelColor label:@"Gray" color:[NSColor grayColor]]forKey:[self keyForLabel:1]];
	[[self dictionary] setObject:[NTLabelColor label:@"Green" color:[NSColor colorWithCalibratedRed:.67 green:.85 blue:0 alpha:1.0]]forKey:[self keyForLabel:2]];
	[[self dictionary] setObject:[NTLabelColor label:@"Purple" color:[NSColor colorWithCalibratedRed:.8 green:.4 blue:1 alpha:1.0]]forKey:[self keyForLabel:3]];
	[[self dictionary] setObject:[NTLabelColor label:@"Blue" color:[NSColor colorWithCalibratedRed:.26 green:.61 blue:1 alpha:1.0]]forKey:[self keyForLabel:4]];
	[[self dictionary] setObject:[NTLabelColor label:@"Yellow" color:[NSColor colorWithCalibratedRed:1 green:.8 blue:.0 alpha:1.0]]forKey:[self keyForLabel:5]];
	[[self dictionary] setObject:[NTLabelColor label:@"Red" color:[NSColor redColor]]forKey:[self keyForLabel:6]];
	[[self dictionary] setObject:[NTLabelColor label:@"Orange" color:[NSColor colorWithCalibratedRed:1 green:.61 blue:.18 alpha:1.0]]forKey:[self keyForLabel:7]];
}

- (NSString*)keyForLabel:(unsigned)label;
{
	return [NSString stringWithFormat:@"label%d", label];
}

- (void)saveToPreferences;
{
	// dump cached gradients
	self.gradients = [NSMutableDictionary dictionary];

    if (![self saveInProgress])
	{
		[self setSaveInProgress:YES];

		[self performSelector:@selector(doSaveToPreferencesAfterDelay:) withObject:nil afterDelay:1];
	}
}

- (void)doSaveToPreferencesAfterDelay:(id)unused;
{	
	// send out notification
	[self setBuildID:[self buildID]]; // adds one automatically
	[[NSNotificationCenter defaultCenter] postNotificationName:NTLabelColorMgrNotification object:nil];
	
    // save to preferences
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:[self dictionary]];
    if (data)
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:kLabelsModelKey];
	
	[self setSaveInProgress:NO];
}

- (void)loadFromPreferences;
{
    NSDictionary* result = nil;
    NSData* data = [[NSUserDefaults standardUserDefaults] objectForKey:kLabelsModelKey];
	
    if (data)
        result = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	
	if (result)
		[[self dictionary] addEntriesFromDictionary:result];
}

//---------------------------------------------------------- 
//  saveInProgress 
//---------------------------------------------------------- 
- (BOOL)saveInProgress
{
    return mSaveInProgress;
}

- (void)setSaveInProgress:(BOOL)flag
{
    mSaveInProgress = flag;
}

- (void)startObserving;
{
	NSEnumerator *enumerator = [[self dictionary] objectEnumerator];
	NTLabelColor* color;
	
	while (color = [enumerator nextObject])
		[self startObservingObject:color];
}

- (void)stopObserving;
{
	NSEnumerator *enumerator = [[self dictionary] objectEnumerator];
	NTLabelColor* color;
	
	while (color = [enumerator nextObject])
		[self stopObservingObject:color];
}

- (void)startObservingObject:(id)thisObject
{
    if ([thisObject respondsToSelector:@selector(keyPaths)]) {
        NSEnumerator *e = [[thisObject keyPaths] objectEnumerator];
        NSString *thisKey;
		
        while (thisKey = [e nextObject]) {
            [thisObject addObserver:self
						 forKeyPath:thisKey
							options:NSKeyValueObservingOptionOld
							context:NULL];
        }
    }
}

- (void)stopObservingObject:(id)thisObject
{
    if ([thisObject respondsToSelector:@selector(keyPaths)]) {
        NSEnumerator *e = [[thisObject keyPaths] objectEnumerator];
        NSString *thisKey;
		
        while (thisKey = [e nextObject]) {
            [thisObject removeObserver:self forKeyPath:thisKey];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)key
					  ofObject:(id)object 
                        change:(NSDictionary *)change
                       context:(void *)context;
{
	[self saveToPreferences];
}

@end

