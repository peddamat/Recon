//
//  StringToAttribStringTransformer.m
//  recon
//
//  Created by Sumanth Peddamatham on 8/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "StringToAttribStringTransformer.h"


@implementation StringToAttribStringTransformer

+ (Class)transformedValueClass
{
   return [NSAttributedString class];
}

+ (BOOL)allowsReverseTransformation
{
	return YES;
}


/*
 * Transform NSString to NSAttributedString
 *
 */
- (id)transformedValue:(id)value
{
   if(value == nil)
      return nil;
   
   NSAttributedString* attribString = [[[NSAttributedString alloc] initWithString:(NSString*)value] autorelease];
   return attribString;
}

/*
 * Transform NSAttributedString to NSString
 *
 */
- (id)reverseTransformedValue:(id)value
{
	if(value==nil)
		return nil;
	
	return [(NSAttributedString*)value string];
}

@end
