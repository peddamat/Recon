//
//  NTSVNStatusItem.m
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 12/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTSVNStatusItem.h"

@interface NTSVNStatusItem (Private)
- (NSString*)buildHTML;
+ (NSArray*)extractInfoFromXML:(NSString*)xml;
- (char)statusChar;
- (NTSVNStatusItemStatus)itemStringToStatus:(NSString*)itemString;

- (NSDictionary *)dictionary;
- (void)setDictionary:(NSDictionary *)theDictionary;
@end

@interface NTSVNStatusItem (hidden)
- (void)setHTML:(NSString *)theHTML;
@end

@implementation NTSVNStatusItem

+ (NTSVNStatusItem*)item:(NSDictionary*)info;
{
	NTSVNStatusItem* result = [[NTSVNStatusItem alloc] init];
	
	[result setDictionary:info];
	
	return [result autorelease];
}

// convert xml to an array of items
+ (NSArray*)xmlToItems:(NSString*)xml;
{
	NSMutableArray* result = [NSMutableArray array];
	
	if ([xml length])
	{
		NSArray* array = [self extractInfoFromXML:xml];
		NSDictionary* info;
		
		for (info in array)
			[result addObject:[self item:info]];
		
		[result sortUsingSelector:@selector(compare:)];
	}
	
	return result;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	[self setHTML:nil];
    [self setDictionary:nil];
	
    [super dealloc];
}

- (NSComparisonResult)compare:(NTSVNStatusItem *)right;
{
	return [[self relativePath] compare:[right relativePath]];
}

//---------------------------------------------------------- 
//  relativePath 
//---------------------------------------------------------- 
- (NSString *)relativePath
{
	return [[self dictionary] objectForKey:@"path"]; 
}

//---------------------------------------------------------- 
//  status 
//---------------------------------------------------------- 
- (NTSVNStatusItemStatus)status
{
	if (!mStatus)
		[self setStatus:[self itemStringToStatus:[[self dictionary] objectForKey:@"item"]]];
	
    return mStatus;
}

- (void)setStatus:(NTSVNStatusItemStatus)theStatus
{
    mStatus = theStatus;
	
	// must reset html if this changes
	[self setHTML:nil];
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

@end

@implementation NTSVNStatusItem (Private)

- (NTSVNStatusItemStatus)itemStringToStatus:(NSString*)itemString;
{
	if ([itemString isEqualToString:@"modified"])
		return kModifiedFileStatus;
	else if ([itemString isEqualToString:@"unversioned"])
		return kNewFileStatus; // not sure why this is returning unversioned
	else if ([itemString isEqualToString:@"missing"])
		return kMissingFileStatus;
	else if ([itemString isEqualToString:@"added"])
		return kAddedFileStatus;
	else if ([itemString isEqualToString:@"deleted"])
		return kDeletedFileStatus;
	else if ([itemString isEqualToString:@"ignored"])
		return kIgnoredFileStatus;
	else if ([itemString isEqualToString:@"conflicted"])
		return kConflictFileStatus;
	else if ([itemString isEqualToString:@"replaced"])
		return kReplacedFileStatus;
	
	NSLog(@"-[%@ %@] svn module does not handle: %@", [self className], NSStringFromSelector(_cmd), itemString);
	
    return 666;
}

- (char)statusChar;
{
	switch ([self status])
	{		
		case kNoFileStatus:
			return ' ';
		case kNewFileStatus:
			return '?';
		case kModifiedFileStatus:
			return 'M';
		case kMissingFileStatus:
			return '!';
		case kConflictFileStatus:
			return 'C';
		case kObstructedFileStatus:
			return '~';
		case kUnversionedFileStatus:
			return 'X';
		case kIgnoredFileStatus:
			return 'I';
		case kDeletedFileStatus:
			return 'D';
		case kAddedFileStatus:
			return 'A';
		case kMergedFileStatus:
			return 'M';
		case kReplacedFileStatus:
			return 'R';
		default:
			break;
	}
	
    return '$';
}

- (NSString*)encodePath:(NSString*)path;
{
	// stringByAddingPercentEscapesUsingEncoding isn't strict enough, leaves ? and others non escaped
	CFStringRef stringRef = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)path, NULL, (CFStringRef)@"!$&'()*+,-./:;=?@_~", kCFStringEncodingUTF8);
	if (stringRef)
	{
		path = [NSString stringWithString:(NSString*)stringRef];
		CFRelease(stringRef);
	}
	return path;
}

- (NSString*)buildHTML;
{
	NSMutableString* result = [NSMutableString string];
	
	[result appendString:@"<tr>"];
	{
		int i, addEmpty = 0;
		NSString* path = [self encodePath:[self relativePath]];
		NSString* linkFormat = @"<a href=\"mshp://%@/%@\">%@</a>";
		
		[result appendString:@"<td class=\"status\">"];
		[result appendString:[NSString stringWithFormat:@"<strong>%c</strong>", [self statusChar]]];
		[result appendString:@"</td>"];
		
		if ([self status] == kNewFileStatus)
		{
			[result appendString:@"<td>"];
			[result appendString:[NSString stringWithFormat:linkFormat, @"add", path, @"add"]];				
			[result appendString:@"</td>"];
		}
		else
			addEmpty++;
		
		if ([self status] == kMissingFileStatus)
		{
			[result appendString:@"<td>"];
			[result appendString:[NSString stringWithFormat:linkFormat, @"rm", path, @"rm"]];				
			[result appendString:@"</td>"];
		}
		else
			addEmpty++;
		
		if ([self status] == kModifiedFileStatus)
		{
			[result appendString:@"<td class=\"diff\">"];
			[result appendString:[NSString stringWithFormat:linkFormat, @"diff", path, @"diff"]];				
			[result appendString:@"</td>"];
		}
		else
			addEmpty++;
		
		if ([self status] == kModifiedFileStatus)
		{
			[result appendString:@"<td class=\"revert\">"];
			[result appendString:[NSString stringWithFormat:linkFormat, @"revert", path, @"revert"]];				
			[result appendString:@"</td>"];
		}
		else
			addEmpty++;
		
		for (i=0;i<addEmpty;i++)
		{
			[result appendString:@"<td>"];
			[result appendString:@" "];
			[result appendString:@"</td>"];
		}
	}
	
	[result appendString:@"<td class=\"filepath\">"];
	[result appendString:[self relativePath]];
	[result appendString:@"</td>"];
	
	[result appendString:@"</tr>"];
	
	return result;
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

+ (NSArray*)extractInfoFromXML:(NSString*)xml;
{
	NSMutableArray* result=[NSMutableArray array];
	
	if ([xml length])
	{		
		NSData* data = [xml dataUsingEncoding:NSUTF8StringEncoding];
		if ([data length])
		{
			NSError *error=nil;
			NSXMLDocument* xmlDoc = nil;
			
			@try {
				xmlDoc = [[[NSXMLDocument alloc] initWithData:data options:0 error:&error] autorelease];		
			}
			@catch (NSException * e) {
				xmlDoc = nil;
			}
			
			if (xmlDoc)
			{
				// set yes to debug
				if (NO)
				{
					NSData *xmlData = [xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
					NSString* output = [[[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding] autorelease];
					NSLog(@"%@", output);
				}
				
				NSArray *nodes;
				
				error=nil;
				nodes = [[xmlDoc rootElement] objectsForXQuery:@"./target/entry" error:&error];
				
				if (error)
					NSLog(@"%@", [error description]);
				else if ([nodes count])
				{
					NSXMLElement* node;
					NSXMLElement* subNode;
					
					for (node in nodes)
					{
						subNode = (NSXMLElement*)[node attributeForName:@"path"];
						
						NSString* path = [subNode stringValue];
						
						if (path)
						{
							// get the "wc-status"					
							NSArray* childElements = [node elementsForName:@"wc-status"];
							
							if (error)
								NSLog(@"%@", [error description]);
							else if ([childElements count])
							{
								NSEnumerator *elementEnumerator = [childElements objectEnumerator];
								NSXMLElement* element;
								
								while (element = [elementEnumerator nextObject])
								{
									subNode = (NSXMLElement*)[element attributeForName:@"props"];
									NSString* props = [subNode stringValue];
									
									subNode = (NSXMLElement*)[element attributeForName:@"item"];
									NSString* item = [subNode stringValue];
									
									[result addObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"path", props, @"props", item, @"item", nil]];
								}
								
							}
							else
								NSLog(@"no status nodes");
						}
					}
				}
			}
		}
	}
	
	return result;
}

@end
