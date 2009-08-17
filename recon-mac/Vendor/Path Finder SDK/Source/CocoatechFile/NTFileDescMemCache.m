//
//  NTFileDescMemCache.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Fri Sep 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NTFileDescMemCache.h"

#define kCacheCapacity 250
#define kCacheMinimumCapacity 4

@implementation NTFileDescMemCache

+ (void)initialize;
{
    NTINITIALIZE;
    
    // go ahead and build the sharedinstance here, we don't want to wait and run the chance of two threads creating two instances
    [self sharedInstance];
}

+ (NTFileDescMemCache*)sharedInstance;
{
    static NTFileDescMemCache* shared=nil;
    
    if (!shared)
        shared = [[NTFileDescMemCache alloc] init];
    
    return shared;
}

- (id)init;
{
    self = [super init];
    
    _threadLock = [[NSLock alloc] init];
    _free = [[NSMutableArray alloc] initWithCapacity:5];
    
    return self;
}

- (void)dealloc;
{
    [_threadLock release];
    [_free release];

    [super dealloc];
}

- (NTFileDescMem*)checkout;
{
    NTFileDescMem *result = nil;
    
	if ([_threadLock tryLock])
	{
		if ([_free count])
		{
			result = [[[_free objectAtIndex:0] retain] autorelease];
			[_free removeObjectAtIndex:0];
		}
		
		[_threadLock unlock];
	}
	
    if (!result)
        result = [NTFileDescMem cacheWithCapacity:kCacheCapacity];
    	
    return result;
}

- (void)checkin:(NTFileDescMem*)cache;
{
	if ([_threadLock tryLock])
	{    
		if ([_free count] < 4)
			[_free addObject:cache];
		
		[_threadLock unlock];    
	}
}

@end

// ========================================================================================

@implementation NTFileDescMem

- (id)initWithCapacity:(NSUInteger)capacity;
{
    self = [super init];
    	
    _capacity = capacity;
    
    _refArray = (FSRef *) malloc(sizeof(FSRef) * _capacity );
    _catalogInfoArray = (FSCatalogInfo *) malloc(sizeof(FSCatalogInfo) * _capacity );
    _nameArray = (HFSUniStr255 *) malloc(sizeof(HFSUniStr255) * _capacity );

    return self;
}

+ (id)cacheWithCapacity:(NSUInteger)capacity;
{
    NTFileDescMem* result = [[NTFileDescMem alloc] initWithCapacity:capacity];
    
    return [result autorelease];
}

- (void)dealloc;
{
    free((void*) _refArray);
    free((void*) _catalogInfoArray);
	free((void*) _nameArray);

    [super dealloc];
}

- (NSUInteger)capacity;
{
    return _capacity;
}

- (NSUInteger)minimumCapacity;
{
    return kCacheMinimumCapacity;
}

- (FSRef *)refArray;
{
    return _refArray;
}

- (FSCatalogInfo *)catalogInfoArray;
{
    return _catalogInfoArray;
}

- (HFSUniStr255 *)nameArray;
{
    return _nameArray;
}

@end