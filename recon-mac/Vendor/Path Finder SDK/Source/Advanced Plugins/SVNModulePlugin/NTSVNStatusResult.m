//
//  NTSVNStatusResult.m
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 12/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTSVNStatusResult.h"
#import "NTSVNStatusItem.h"

@interface NTSVNStatusResult (Private)
- (NSString*)buildHTML;

- (NSString *)XML;
- (void)setXML:(NSString *)theXML;

- (NSArray *)items;
- (void)setItems:(NSArray *)theItems;
@end

@interface NTSVNStatusResult (hidden)
- (void)setHTML:(NSString *)theHTML;
@end

@implementation NTSVNStatusResult

// send output from task, parse and hold results
+ (NTSVNStatusResult*)result:(NSString*)res;
{
	NTSVNStatusResult* result = [[NTSVNStatusResult alloc] init];
	
	[result setXML:res];
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	[self setXML:nil];
	[self setItems:nil];
	[self setHTML:nil];
	[super dealloc];
}

//---------------------------------------------------------- 
//  HTML 
//---------------------------------------------------------- 
- (NSString *)HTML
{
	if (!mHTML)
		[self setHTML:[self buildHTML]];
	
	return mHTML; 
}

- (void)setHTML:(NSString *)theHTML
{
	if (mHTML != theHTML)
	{
		[mHTML release];
		mHTML = [theHTML retain];
	}
}

- (BOOL)updateForCommand:(NSString*)command path:(NSString*)path;
{
	BOOL success = NO;
	
	// find an item with this path
	NSEnumerator* enumerator = [[self items] objectEnumerator];
	NTSVNStatusItem* item;
	
	while (item = [enumerator nextObject])
	{
		if ([path isEqualToString:[item relativePath]])
		{
			success = YES;
			break;
		}
	}
	
	if (success)
	{
		[self setHTML:nil];  // empty cached html
		
		if ([command isEqualToString:@"add"])
			[item setStatus:kAddedFileStatus];
		else if ([command isEqualToString:@"rm"])
			[item setStatus:kDeletedFileStatus];
		else if ([command isEqualToString:@"revert"])
			[item setStatus:kNoFileStatus];  // file show go away?
	}
	
	return success;
}

@end

@implementation NTSVNStatusResult (Private)

//---------------------------------------------------------- 
//  XML 
//---------------------------------------------------------- 
- (NSString *)XML
{
	return mXML; 
}

- (void)setXML:(NSString *)theXML
{
	if (mXML != theXML)
	{
		[mXML release];
		mXML = [theXML retain];
	}
}

//---------------------------------------------------------- 
//  items 
//---------------------------------------------------------- 
- (NSArray *)items
{
	if (!mItems)
		[self setItems:[NTSVNStatusItem xmlToItems:[self XML]]];
	
	return mItems; 
}

- (void)setItems:(NSArray *)theItems
{
	if (mItems != theItems)
	{
		[mItems release];
		mItems = [theItems retain];
	}
}

- (NSString*)buildHTML;
{
	NSMutableString* result = [NSMutableString string];
	
	if ([[self items] count])
	{
		NSEnumerator* enumerator = [[self items] objectEnumerator];
		NTSVNStatusItem* item;
		
		[result appendString:@"<table><tbody>"];
		while (item = [enumerator nextObject])
		{
			[result appendString:[item HTML]];
		}
		
		[result appendString:@"</tbody></table>"];
	}
	else
	{
		[result appendString:@"<p align=\"center\">svn status: no modification found</p>"];
	}
	
	return result;
}
	
	
		
@end


	
	
	
	
	
