//
//  NTITunesTrack.m
//  iLike
//
//  Created by Steve Gehrman on 12/4/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTITunesTrack.h"
#import "GBUtilities.h"
#import "NTiLikeXMLUtilities.h"

@interface NTITunesTrack (Private)
- (NSDictionary *)dictionary;
- (void)setDictionary:(NSDictionary *)theDictionary;

- (int)audioFlag;
- (void)setAudioFlag:(int)theAudioFlag;
@end

@interface NTITunesTrack (hidden)
- (void)setDateAdded:(NSDate *)theDateAdded;
- (void)setTrackID:(NSNumber *)theTrackID;
- (void)setCanonicalArtist:(NSString *)theCanonicalArtist;
@end

@implementation NTITunesTrack

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setDictionary:nil];
	[self setCanonicalArtist:nil];
    [self setDateAdded:nil];
    [self setTrackID:nil];

    [super dealloc];
}

+ (NTITunesTrack*)track:(NSDictionary*)dictionary;
{
	NTITunesTrack* result = [[NTITunesTrack alloc] init];
	
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

		// artist name must be set
		if ([[self artist] length])
		{
			// must be a file
			NSString* trackType = [[self dictionary] objectForKey:@"Track Type"];
			if ([trackType isEqualToString:@"File"])
			{
				// must have a "Location", maybe a missing file, not confirmed, but some tracks have no location
				if ([[self dictionary] objectForKey:@"Location"])
				{					
					NSString* kind = [[self dictionary] objectForKey:@"Kind"];
					
					// must include the string "audio"
					if ([kind rangeOfString:@"audio"].location != NSNotFound)
					{
						if (![self podcast])
						{
							if ([NTITunesTrack genreIsMusic:[[self dictionary] objectForKey:@"Genre"]])
								[self setAudioFlag:1];
						}
					}
				}
			}
		}
	}
	
	return ([self audioFlag] == 1);
}

- (NSString*)album;
{
	return [[self dictionary] objectForKey:@"Album"];
}

- (NSString*)artist;
{
	return [[self class] artist:[self dictionary]];
}

- (int)playCount;
{
	return [[self class] playCount:[self dictionary]];
}

- (BOOL)podcast;
{
	NSNumber* podcast = [[self dictionary] objectForKey:@"Podcast"];
	
	return [podcast boolValue];
}
	
- (int)rating;
{
	return [[[self dictionary] objectForKey:@"Rating"] intValue];
}

- (NSString*)description;
{
	return [NSString stringWithFormat:@"%@: (%@) \"%@\"", [self artist], [[self trackID] description], [self name]];
	//	return [NSString stringWithFormat:@"%@", [[self dictionary] description]];
}

//---------------------------------------------------------- 
//  dateAdded 
//---------------------------------------------------------- 
- (NSDate *)dateAdded
{
	if (!mDateAdded)
	{
		NSDate *date = [NTiLikeXMLUtilities dateFromString:[[self dictionary] objectForKey:@"Date Added"]];			
		
		if (!date)
			date = [NSDate date];  // shouldn't happen, but don't want nil
		
		[self setDateAdded:date];
	}
	
    return mDateAdded; 
}

- (void)setDateAdded:(NSDate *)theDateAdded
{
    if (mDateAdded != theDateAdded)
    {
        [mDateAdded release];
        mDateAdded = [theDateAdded retain];
    }
}

//---------------------------------------------------------- 
//  trackID 
//---------------------------------------------------------- 
- (NSNumber *)trackID
{
	if (!mTrackID)
		[self setTrackID:[NSNumber numberWithInt:[[[self dictionary] objectForKey:@"Track ID"] intValue]]];
	
    return mTrackID; 
}

- (void)setTrackID:(NSNumber *)theTrackID
{
    if (mTrackID != theTrackID)
    {
        [mTrackID release];
        mTrackID = [theTrackID retain];
    }
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

- (NSComparisonResult)compare:(NTITunesTrack *)right;
{
    long rating1 = [self rating];
    long rating2 = [right rating];
	
    // First, if one has a 4 star or greater rating, it comes first
    if(rating1 >= MAX(rating2, 80))
        return NSOrderedAscending;
    else if(rating2 >= MAX(rating1, 80))
        return NSOrderedDescending;
    else if (rating2 != 0 && rating2 <= 40 && (rating1 == 0 || rating2 < rating1 ))
        return NSOrderedAscending;
    else if (rating1 != 0 && rating1 <= 40 && (rating2 == 0 || rating1 < rating2 ))
        return NSOrderedDescending;
	
    // If neither is rated highly, use playcounts
    long playcount1 = [self playCount];
    long playcount2 = [right playCount];
	
    if (playcount1 > playcount2)
        return NSOrderedAscending;
    else if (playcount2 > playcount1)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

@end

@implementation NTITunesTrack (Private)

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

@implementation NTITunesTrack (Utils)

+ (NSString*)artist:(NSDictionary*)dictionary;
{
	return [dictionary objectForKey:@"Artist"];
}

+ (NSURL*)url:(NSDictionary*)dictionary;
{
	NSString *urlString = [dictionary objectForKey:@"Location"];
	
	if (urlString)
		return [NSURL URLWithString:urlString];
	
	return nil;
}

+ (NSString*)trackID:(NSDictionary*)dictionary;
{
	return [dictionary objectForKey:@"Track ID"];
}

+ (int)playCount:(NSDictionary*)dictionary;
{
	return [[dictionary objectForKey:@"Play Count"] intValue];
}

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

@end

