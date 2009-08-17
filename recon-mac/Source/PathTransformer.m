//
//  PathTransformer.m
//  recon
//
//  Created by Sumanth Peddamatham on 8/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PathTransformer.h"

@implementation PathTransformer

+ (Class)transformedValueClass
{
   return [NSString self];   
}

+ (BOOL)allowsReverseTransformation
{
   return NO;
}

- (id)transformedValue:(id)beforeObject
{
   if (beforeObject == nil) return nil;
   
   if ([beforeObject isEqualToString:@"UP"] == YES)
   {
      id resourcePath = [[NSBundle mainBundle] resourcePath];
      return [resourcePath stringByAppendingPathComponent:@"checkbox_medium_blank-N.png"];
   }
   else if ([beforeObject isEqualToString:@"DOWN"] == YES)
   {
      id resourcePath = [[NSBundle mainBundle] resourcePath];
      return [resourcePath stringByAppendingPathComponent:@"checkbox_red-N.png"];
   }   
   else
   {
      id resourcePath = [[NSBundle mainBundle] resourcePath];
      return [resourcePath stringByAppendingPathComponent:@"checkbox_yellow-N.png"];
   }      
}


@end