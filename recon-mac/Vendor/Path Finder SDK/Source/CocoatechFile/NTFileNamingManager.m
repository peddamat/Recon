//
//  NTFileNamingManager.m
//  CocoatechFile
//
//  Created by sgehrman on Sun Aug 12 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NTFileNamingManager.h"
#import "NTPathUtilities.h"

@interface NTFileNamingManager (Private)
- (BOOL)isNameReserved:(NSString*)path;
- (void)addName:(NSString*)path;
- (void)removeName:(NSString*)path;
@end

// When you have async file commands happening, you can't just look at the contents of the disk
// to determine if a file name is unused.  For example, you could start a thread that duplicates a folder named
// "xyz", the thread looks at the disk and sees that "xyz copy" is a valid name to give to duplicate.  Before that
// thread has a chance to create the new folder, you issue a rename or even another duplicate command.  There is a chance that
// the code could pick "xyz copy" as a valid name and then one of the two operations would fail.
// The purpose of this code is keep a list of filenames currently being used by the program.  Any code dealing with
// creating, renaming, or moving files should consult this manager to see if the name has been reserved.

@implementation NTFileNamingManager

+ (void)initialize;
{
    NTINITIALIZE;
    
    // go ahead and build the sharedinstance here, we don't want to wait and run the chance of two threads creating two instances
    [NTFileNamingManager sharedInstance];
}

+ (NTFileNamingManager*)sharedInstance;
{
    static NTFileNamingManager* shared = nil;
	
    if (shared == nil)
        shared = [[NTFileNamingManager alloc] init];
	
    return shared;
}

- (id)init
{
    self = [super init];
	
    _nameReserve = [[NSMutableArray alloc] init];
	
    return self;
}

- (void)dealloc
{
    [_nameReserve release];
    [super dealloc];
}

- (void)reserveName:(NSString*)path;
{
    // can be called from threads, keep them from overlapping in this code
    [self addName:path];
}

// returns a unique name and reserves it in the _nameReserve, you must call releaseName after
// the real file has been created, or the user cancels the operation
- (void)releaseName:(NSString*)path;
{
    [self removeName:path];
}

// checks reserve and the disk (like uniqueName)
- (BOOL)isUnique:(NSString*)path;
{
    BOOL isUnique;
	
    // first check if the name is reserved in our database
    isUnique = ![self isNameReserved:path];
	
    // if not in our database, check the disk
    if (isUnique)
    {
        // if not in our database, check the disk
        isUnique = ![NTPathUtilities pathOK:path];
    }
	
    return isUnique;
}

// returns a unique name at path with optional with: copy, alias etc
// if you pass in /xyz/hello.jpg withDesc:@"copy" you will get /xyz/hello copy 2.jpg for example
- (NSString*)uniqueName:(NSString*)path with:(NSString*)with;
{
    NSString* parentDirectory = [path stringByDeletingLastPathComponent];
    NSMutableString* itemName;
    NSString* resultPath;
    NSString* ext = [path strictPathExtension];
    int count=2;
	
    itemName = [NSMutableString stringWithString:[[path lastPathComponent] strictStringByDeletingPathExtension]];
	
	if ([itemName rangeOfString:[NSString stringWithFormat:@" %@ ", with]].location != NSNotFound)
	{
		// see if we have something like xyx copy 3
		NSArray * components = [itemName componentsSeparatedByString:@" "];
		if ([components count] > 1)
		{
			NSRange range;
			NSString* last = [components objectAtIndex:[components count]-1];
			int i, cnt = [components count];
			
			// see if the last component is a number
			range = [last rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]];
			if (range.length == [last length])
			{
				count = [last intValue];
				
				// reconstruct string without number
				itemName = [NSMutableString string];  // clear out the string
				for (i=0;i<cnt-1;i++)
				{
					if (i>0)
						[itemName appendString:@" "];
					
					[itemName appendString:[components objectAtIndex:i]];
				}
			}
		}
	}
		
    if (with && [with length])
    {
        NSString* descString = [@" " stringByAppendingString:with];
		
        // check to see if the file already has the desc (and don't add it again)
        // may have " copy 2" so take off the " 2" before test
        if (![itemName hasSuffix:descString])
            [itemName appendString:descString];
    }
	
    resultPath = [parentDirectory stringByAppendingPathComponent:itemName];
    if (ext && [ext length])
        resultPath = [resultPath stringByAppendingPathExtension:ext];
	
    if (![self isUnique:resultPath])
    {
        // loop to find unique name
        do
        {
            resultPath = [parentDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ %d", itemName, count++]];
            if (ext && [ext length])
                resultPath = [resultPath stringByAppendingPathExtension:ext];
			
        } while (![self isUnique:resultPath]);
    }
	
    return resultPath;
}

@end

@implementation NTFileNamingManager (Private)

// private functions don't lock, since they are used within locked code
- (BOOL)isNameReserved:(NSString*)path;
{
    int i, cnt;
    BOOL reserved = NO;
	
    // can be called from threads, keep them from overlapping in this code
    @synchronized(self) {
		
		cnt = [_nameReserve count];
		for (i=0;i<cnt;i++)
		{
			if ([path isEqualToString:[_nameReserve objectAtIndex:i]])
			{
				reserved = YES;
				break;
			}
		}
    }
	
    return reserved;
}

- (void)addName:(NSString*)path;
{
    // can be called from threads, keep them from overlapping in this code
    @synchronized(self) {
		[_nameReserve addObject:path];
    }
}

- (void)removeName:(NSString*)path;
{
    int i, cnt;
	
    // can be called from threads, keep them from overlapping in this code
    @synchronized(self) {
		
		cnt = [_nameReserve count];
		for (i=0;i<cnt;i++)
		{
			if ([path isEqualToString:[_nameReserve objectAtIndex:i]])
			{
				[_nameReserve removeObjectAtIndex:i];
				break;
			}
		}
    }
}

@end
