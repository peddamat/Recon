//
//  NTOpenWithUIModel.m
//  OpenWithModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTOpenWithUIModel.h"

@interface NTOpenWithUIModel (Private)
@end

@implementation NTOpenWithUIModel

+ (NTOpenWithUIModel*)model;
{
	NTOpenWithUIModel* result = [[NTOpenWithUIModel alloc] init];
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setDescs:nil];
    [self setItems:nil];
    [self setSelectedItem:nil];
    [super dealloc];
}

//---------------------------------------------------------- 
//  initialized 
//---------------------------------------------------------- 
- (BOOL)initialized
{
    return mInitialized;
}

- (void)setInitialized:(BOOL)flag
{
    mInitialized = flag;
}

//---------------------------------------------------------- 
//  changeAllEnabled 
//---------------------------------------------------------- 
- (BOOL)changeAllEnabled
{
    return mChangeAllEnabled;
}

- (void)setChangeAllEnabled:(BOOL)flag
{
    mChangeAllEnabled = flag;
}

- (NTFileDesc*)firstDesc;
{
	if ([[self descs] count])
		return [[self descs] objectAtIndex:0];
		
	return nil;
}

//---------------------------------------------------------- 
//  descs 
//---------------------------------------------------------- 
- (NSArray *)descs
{
    return mDescs; 
}

- (void)setDescs:(NSArray *)theDescs
{
    if (mDescs != theDescs)
    {
        [mDescs release];
        mDescs = [theDescs retain];
    }
}
	
//---------------------------------------------------------- 
//  items 
//---------------------------------------------------------- 
- (NSArray *)items
{
    return mItems; 
}

- (void)setItems:(NSArray *)theItems
{
    if (mItems != theItems)
    {
        [mItems release];
        mItems = [theItems retain];
		
		[self setInitialized:[mItems count]];
    }
}

//---------------------------------------------------------- 
//  selectedItem 
//---------------------------------------------------------- 
- (id)selectedItem
{
    return mSelectedItem; 
}

- (void)setSelectedItem:(id)theSelectedItem
{
    if (mSelectedItem != theSelectedItem)
    {
		[mSelectedItem release];
		mSelectedItem = [theSelectedItem retain];

		if ([self initialized])
		{
			// item was selected!  perform a command
			switch ([mSelectedItem command])
			{
				case kChoosePopupCommand:
					[NTChooseFilePanel openFile:[[NTDefaultDirectory sharedInstance] applicationsPath] window:nil target:self selector:@selector(changeApplicationBindingSelector:) fileType:kApplicationFileType];
					break;
				default:
				{
					if ([mSelectedItem desc])
					{
						NSEnumerator *enumerator = [[self descs] objectEnumerator];
						NTFileDesc* desc;
						
						while (desc = [enumerator nextObject])
							[NTFileAttributeModifier setApplicationBinding:[mSelectedItem desc] forFile:desc];
					}
				}
					break;
			}
		}
	}
}

@end

@implementation NTOpenWithUIModel (Private)

- (void)changeApplicationBindingSelector:(NTChooseFilePanel*)sender;
{
	if ([sender userClickedOK])
	{
		NTFileDesc* appDesc = [NTFileDesc descResolve:[sender path]];
	    
        if (appDesc && [appDesc isValid])
		{
			NSEnumerator *enumerator = [[self descs] objectEnumerator];
			NTFileDesc* desc;
			
			while (desc = [enumerator nextObject])
				[NTFileAttributeModifier setApplicationBinding:appDesc forFile:desc];
		}
    }
	
	// must set this back (the user could have canceled, so we always want to get back to the right app
	NTFileDesc* currentApp = [[[self firstDesc] newDesc] application];
	if (![currentApp isValid])
		currentApp = nil;
	
	if (currentApp)
		[self setSelectedItem:[NTOpenWithUIModelItem item:currentApp]];
}

@end

