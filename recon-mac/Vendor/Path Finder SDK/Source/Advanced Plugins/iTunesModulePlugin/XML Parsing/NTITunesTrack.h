//
//  NTITunesTrack.h
//  iLike
//
//  Created by Steve Gehrman on 12/4/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTITunesTrack : NSObject {
	NSDictionary* mDictionary;
	
	NSString* mCanonicalArtist;
	NSDate* mDateAdded;
	NSNumber* mTrackID;
	
	int mAudioFlag;
}

+ (NTITunesTrack*)track:(NSDictionary*)dictionary;

- (BOOL)isMusic;

- (NSString*)artist;
- (NSString *)canonicalArtist;

- (NSString*)name;
- (NSString*)album;
- (NSNumber*)trackID;
- (NSDate*)dateAdded;
- (BOOL)podcast;

- (int)playCount;
- (int)rating;

- (NSComparisonResult)compare:(NTITunesTrack *)right;

@end

@interface NTITunesTrack (Utils)
+ (NSString*)artist:(NSDictionary*)dictionary;
+ (int)playCount:(NSDictionary*)dictionary;
+ (NSURL*)url:(NSDictionary*)dictionary;
+ (NSString*)trackID:(NSDictionary*)dictionary;

+ (BOOL)genreIsMusic:(NSString*)genre;
@end
