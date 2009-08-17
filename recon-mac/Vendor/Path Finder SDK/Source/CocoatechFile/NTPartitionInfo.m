//
//  NTPartitionInfo.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/17/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTPartitionInfo.h"
#import "NTVolume.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/storage/IOMedia.h>
#include <IOKit/IOBSD.h>

@interface NTPartitionInfo (Private)
+ (BOOL)boolProperty:(NSString*)property forService:(io_service_t)service;
+ (NSString*)stringProperty:(NSString*)property forService:(io_service_t)service;
@end

@implementation NTPartitionInfo

+ (NSArray*)siblingEjectablePartitionsForVolume:(NTVolume*)volume;
{    
	NSString* inBSDName = [volume diskIDString];
	CFMutableDictionaryRef  matchingDict = IOBSDNameMatching(kIOMasterPortDefault, 0, [inBSDName UTF8String]);
	NSMutableArray* result = [NSMutableArray array];
	
	io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, matchingDict);    
	if (service != IO_OBJECT_NULL)
	{
		kern_return_t	kernResult;
		io_iterator_t	iter;
		io_service_t parent;
		
		kernResult = IORegistryEntryGetParentEntry(service,kIOServicePlane, &parent);
		
		if ((kernResult == KERN_SUCCESS) && parent) 
		{
			// Create an iterator across all parents of the service object passed in.
			kernResult = IORegistryEntryCreateIterator(parent,
													   kIOServicePlane,
													   kIORegistryIterateRecursively,
													   &iter);
			
			if ((kernResult == KERN_SUCCESS) && iter) 
			{
				BOOL isOpen;
				io_service_t childService;
				
				while ((childService = IOIteratorNext(iter))) 
				{
					isOpen = [self boolProperty:(NSString*)CFSTR(kIOMediaOpenKey) forService:childService];
					
					if (isOpen)
					{
						// get the drive name using DiskArbitration
						NSString* bsdName = [self stringProperty:(NSString*)CFSTR(kIOBSDNameKey) forService:childService];
						
						if (bsdName)
						{
							if (![inBSDName isEqualToString:bsdName])
								[result addObject:bsdName];
						}
					}
					
					IOObjectRelease(childService);
				}
				
				IOObjectRelease(iter);
			}		
			
			IOObjectRelease(parent);
		}
		IOObjectRelease(service);
	}
	
	return result;
}

@end

@implementation NTPartitionInfo (Private)

+ (BOOL)boolProperty:(NSString*)property forService:(io_service_t)service;
{    
    Boolean result = NO;
	
	CFTypeRef resRef;
	
	resRef = IORegistryEntryCreateCFProperty(service, 
											 (CFStringRef)property, 
											 kCFAllocatorDefault, 
											 0);
	
	if (resRef) 
	{                                        
		result = CFBooleanGetValue(resRef);
		CFRelease(resRef);
	}
	
    return result;
}

+ (NSString*)stringProperty:(NSString*)property forService:(io_service_t)service;
{    
    NSString *result = nil;
	
	CFStringRef resRef;
	
	resRef = IORegistryEntryCreateCFProperty(service, 
											 (CFStringRef)property, 
											 kCFAllocatorDefault, 
											 0);
	
	if (resRef) 
	{                                        
		result = [NSString stringWithString:(NSString*)resRef];
		CFRelease(resRef);
	}
	
    return result;
}

@end
