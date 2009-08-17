//
//  NTITunesTrackElementDict.m
//  iLike
//
//  Created by Steve Gehrman on 2/13/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTITunesTrackElementDict.h"
#import "GBUtilities.h"
#import "NTiLikeXMLUtilities.h"

@interface NTITunesTrackElementDict (Private)
- (NSDictionary *)dictionary;
- (void)setDictionary:(NSDictionary *)theDictionary;

- (NSTimeInterval)addedTime;
- (void)setAddedTime:(NSTimeInterval)theAddedTime;

- (NSTimeInterval)playedTime;
- (void)setPlayedTime:(NSTimeInterval)thePlayedTime;

- (NSTimeInterval)modifiedTime;
- (void)setModifiedTime:(NSTimeInterval)theModifiedTime;

- (int)audioFlag;
- (void)setAudioFlag:(int)theAudioFlag;
@end

@interface NTITunesTrackElementDict (hidden)
- (void)setCanonicalArtist:(NSString *)theCanonicalArtist;
@end

@implementation NTITunesTrackElementDict

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setDictionary:nil];
	[self setCanonicalArtist:nil];
	
    [super dealloc];
}

+ (NTITunesTrackElementDict*)track:(NSDictionary*)dictionary;
{
	NTITunesTrackElementDict* result = [[NTITunesTrackElementDict alloc] init];
	
	[result setDictionary:dictionary];
	
	return [result autorelease];
}

- (NSString*)name;
{
	return [[self dictionary] objectForKey:@"Name"];
}

- (BOOL)isMusic;
{
	if ([self audioFlag] == 0)
	{
		[self setAudioFlag:-1]; // -1 is NO, 0 is undefined
		
		if ([NTITunesTrackElementDict isMusic:[self dictionary]])
			[self setAudioFlag:1];
	}
	
	return ([self audioFlag] == 1);
}

- (NSString*)album;
{
	return [[self dictionary] objectForKey:@"Album"];
}

- (NSString*)artist;
{
	return [[self dictionary] objectForKey:@"Artist"];
}

- (NSString*)playCount;
{
	return [[self dictionary] objectForKey:@"Play Count"];
}

- (BOOL)podcast;
{
	NSString* podcast = [[self dictionary] objectForKey:@"Podcast"];
	
	// assume there is never a false ("true" is YES)
	return (podcast != nil);
}

- (NSString*)rating;
{
	return [[self dictionary] objectForKey:@"Rating"];
}

- (NSString*)dateAdded;
{
	return [[self dictionary] objectForKey:@"Date Added"];
}

- (NSString*)description;
{
	return [NSString stringWithFormat:@"%@", [[self dictionary] description]];
}

- (NSString*)trackID;
{
	return [[self dictionary] objectForKey:@"Track ID"];
}

- (BOOL)hasDateNewerThanDate:(NSDate*)date now:(NSTimeInterval)now;
{	
	NSTimeInterval interval = 0;
	if (date)
		interval = [date timeIntervalSinceReferenceDate];
	
	if (([self addedTime] > interval) && ([self addedTime] <= now))
		return YES;
	
	if (([self modifiedTime] > interval) && ([self modifiedTime] <= now))
		return YES;
	
	if (([self playedTime] > interval) && ([self playedTime] <= now))
		return YES;
	
	return NO;
}

- (NSDate*)maxDate:(NSDate*)date now:(NSTimeInterval)now;
{
	NSTimeInterval interval = 0;
	if (date)
		interval = [date timeIntervalSinceReferenceDate];
	
	// get max interval
	NSTimeInterval maxInterval = MAX([self addedTime], MAX([self modifiedTime], [self playedTime]));
	
	if (maxInterval > interval)
	{		
		// don't include wacky dates in the future - my library had dates of 2036 - probably added tracks when clock was wrong
		if (maxInterval <= now)
		{
			NSDate* maxDate = [NSDate dateWithTimeIntervalSinceReferenceDate:maxInterval];
			
			return maxDate;
		}
	}
	
	return date;
}

//---------------------------------------------------------- 
//  canonicalArtist 
//---------------------------------------------------------- 
- (NSString *)canonicalArtist
{
	if (!mCanonicalArtist)
		[self setCanonicalArtist:[[self artist] GB_canonicalString]];
	
    return mCanonicalArtist; 
}

- (void)setCanonicalArtist:(NSString *)theCanonicalArtist
{
    if (mCanonicalArtist != theCanonicalArtist)
    {
        [mCanonicalArtist release];
        mCanonicalArtist = [theCanonicalArtist retain];
    }
}

- (NSString*)hash;
{
	return [NSString stringWithFormat:@"%u-%u-%u", [[self name] hash], [[self album] hash], [[self artist] hash]];
}

- (NSString*)xml:(BOOL)inPlaylist;
{		
	NSXMLElement *node=nil;
	
	// clean up trackDict with our new keys
	NSDictionary *cleanDict = [NTiLikeXMLUtilities cleanInfoDict:[self dictionary]];
	
	node = [NSXMLElement elementWithName:@"track"];
	NSXMLNode *child;
	NSString *key, *obj;
	
	NSEnumerator *enumerator = [[NSArray arrayWithObjects:
		@"id",
		@"artist",
		@"album",
		@"name",
		@"genre",
		@"tplay",
		@"tmod",
		@"tadd",
		@"format",
		@"plays",
		@"source",
		nil] objectEnumerator];		
	
	while (key = [enumerator nextObject])
	{			
		child = nil;
		
		obj = [cleanDict objectForKey:key];
		if ([obj length])  // we don't want empties: <name></name>
		{
			if ([key isEqualToString:@"id"])
			{
				[node addAttribute:[NSXMLNode attributeWithName:key stringValue:[NSString stringWithFormat:@"i%@", obj]]];
				
				// add the ref=1 if trackid is in a playlist
				if (inPlaylist)
					[node addAttribute:[NSXMLNode attributeWithName:@"ref" stringValue:@"1"]];
			}
			else 
			{
				if ([key isEqualToString:@"format"]) // format is some localized string like MPEG audio, ignore this and get the extension
				{
					NSURL* url = [NSURL URLWithString:[[self dictionary] objectForKey:@"Location"]];
					
					if ([url isFileURL])
						obj = [[url path] pathExtension];
				}
				
				child = [NSXMLNode elementWithName:key stringValue:obj];
			}
		}
		
		if (child)
			[node addChild:child];
	}
	
	return [node XMLStringWithOptions:NSXMLNodeOptionsNone];
}

@end

@implementation NTITunesTrackElementDict (Private)

//---------------------------------------------------------- 
//  addedTime 
//---------------------------------------------------------- 
- (NSTimeInterval)addedTime
{
	if (mAddedTime == 0)
	{
		NSString* dateString = [[self dictionary] objectForKey:@"Date Added"];
		if (dateString)
		{
			NSDate* date = [NTiLikeXMLUtilities dateFromString:dateString];
			if (date)
				[self setAddedTime:[date timeIntervalSinceReferenceDate]];
		}
	}
	
    return mAddedTime;
}

- (void)setAddedTime:(NSTimeInterval)theAddedTime
{
    mAddedTime = theAddedTime;
}

//---------------------------------------------------------- 
//  playedTime 
//---------------------------------------------------------- 
- (NSTimeInterval)playedTime
{
	if (mPlayedTime == 0)
	{
		NSString* dateString = [[self dictionary] objectForKey:@"Play Date UTC"];
		if (dateString)
		{
			NSDate* date = [NTiLikeXMLUtilities dateFromString:dateString];
			if (date)
				[self setPlayedTime:[date timeIntervalSinceReferenceDate]];
		}
	}
	
    return mPlayedTime;
}

- (void)setPlayedTime:(NSTimeInterval)thePlayedTime
{
    mPlayedTime = thePlayedTime;
}

//---------------------------------------------------------- 
//  modifiedTime 
//---------------------------------------------------------- 
- (NSTimeInterval)modifiedTime
{
	if (mModifiedTime == 0)
	{
		NSString* dateString = [[self dictionary] objectForKey:@"Date Modified"];
		if (dateString)
		{
			NSDate* date = [NTiLikeXMLUtilities dateFromString:dateString];
			if (date)
				[self setModifiedTime:[date timeIntervalSinceReferenceDate]];
		}
	}
	
    return mModifiedTime;
}

- (void)setModifiedTime:(NSTimeInterval)theModifiedTime
{
    mModifiedTime = theModifiedTime;
}

//---------------------------------------------------------- 
//  dictionary 
//---------------------------------------------------------- 
- (NSDictionary *)dictionary
{
    return mDictionary; 
}

- (void)setDictionary:(NSDictionary *)theDictionary
{
    if (mDictionary != theDictionary)
    {
        [mDictionary release];
        mDictionary = [theDictionary retain];
    }
}

//---------------------------------------------------------- 
//  audioFlag 
//---------------------------------------------------------- 
- (int)audioFlag
{
    return mAudioFlag;
}

- (void)setAudioFlag:(int)theAudioFlag
{
    mAudioFlag = theAudioFlag;
}

@end

@implementation NTITunesTrackElementDict (Utils)

+ (BOOL)genreIsMusic:(NSString*)genre;
{
	if ([genre isEqualToString:@"Podcast"]) 
		return NO;
	
	if ([genre isEqualToString:@"Spoken Word"])
		return NO;

	if ([genre isEqualToString:@"Audiobooks"])
		return NO;

	if ([genre isEqualToString:@"Books & Spoken"])
		return NO;
	
	return YES;
}

+ (BOOL)isMusic:(NSDictionary*)dictionary;
{
	// artist name must be set
	if ([[dictionary objectForKey:@"Artist"] length])
	{
		// must be a file
		NSString* trackType = [dictionary objectForKey:@"Track Type"];
		if ([trackType isEqualToString:@"File"])
		{
			NSString *location = [dictionary objectForKey:@"Location"];
			
			// must have a "Location", maybe a missing file, not confirmed, but some tracks have no location
			// must be at least 11 chars long. Min file length includes file:// and extension
			if ([location length] > 11)
			{
				NSURL *locationURL = [NSURL URLWithString:location];
				
				if ([locationURL isFileURL])
				{				
					NSString* ext = [[locationURL path] pathExtension];
					
					// check extension
					if ([GBUtilities extensionIsMusic:ext])
					{
						if (![dictionary objectForKey:@"Podcast"]) // assuming not a podcast if key doesn't exist
						{
							if ([NTITunesTrackElementDict genreIsMusic:[dictionary objectForKey:@"Genre"]])
								return YES;
						}
					}
				}
			}
		}
	}
	
	return NO;
}

@end

