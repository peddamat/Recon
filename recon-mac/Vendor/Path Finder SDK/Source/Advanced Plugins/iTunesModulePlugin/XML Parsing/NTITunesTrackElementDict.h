//
//  NTITunesTrackElementDictElementDict.h
//  iLike
//
//  Created by Steve Gehrman on 2/13/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTITunesTrackElementDict : NSObject {
	NSDictionary* mDictionary;
	
	NSString* mCanonicalArtist;
	
	int mAudioFlag;	
	
	// dates
	NSTimeInterval mAddedTime;
	NSTimeInterval mPlayedTime;
	NSTimeInterval mModifiedTime;
}

+ (NTITunesTrackElementDict*)track:(NSDictionary*)dictionary;

- (BOOL)isMusic;

- (NSString*)artist;
- (NSString *)canonicalArtist;

- (NSString*)name;
- (NSString*)album;
- (NSString*)trackID;
- (NSString*)dateAdded;
- (BOOL)podcast;

- (NSString*)playCount;
- (NSString*)rating;

- (NSString*)hash; // used for comparison (name, album, artist)

- (NSString*)xml:(BOOL)inPlaylist;
- (BOOL)hasDateNewerThanDate:(NSDate*)date now:(NSTimeInterval)now;
- (NSDate*)maxDate:(NSDate*)date now:(NSTimeInterval)now;
@end

@interface NTITunesTrackElementDict (Utils)
+ (BOOL)genreIsMusic:(NSString*)genre;
+ (BOOL)isMusic:(NSDictionary*)dictionary;
@end
