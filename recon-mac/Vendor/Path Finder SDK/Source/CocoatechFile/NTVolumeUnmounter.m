//
//  NTVolumeUnmounter.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/4/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTVolumeUnmounter.h"
#import "NTPartitionInfo.h"

@interface NTVolumeUnmounter (Private)
- (void)doUnmountVolume;
- (void)doEjectVolume;
@end

@implementation NTVolumeUnmounter

@synthesize volumeOp;
@synthesize ejectUPP;
@synthesize unmountUPP;
@synthesize desc;

- (id)init;
{
    self = [super init];
    
	FSVolumeOperation op;
	OSStatus err = FSCreateVolumeOperation(&op);
	
	if (err == noErr)
		self.volumeOp = op;
	
    return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc;
{
	if (self.volumeOp)
	{
		FSDisposeVolumeOperation(self.volumeOp);
		self.volumeOp = nil;
	}
	
    if (self.unmountUPP)
	{
		DisposeFSVolumeUnmountUPP(self.unmountUPP);
		self.unmountUPP = nil;
	}
	
    if (self.ejectUPP)
	{
        DisposeFSVolumeEjectUPP(self.ejectUPP);
		self.ejectUPP = nil;
	}
	
    self.desc = nil;
    
    [super dealloc];
}

+ (void)ejectVolumeWithModifiers:(NTFileDesc*)theDesc;
{
	BOOL controlKeyDown = [NSEvent controlKeyDownNow];
	
	if (controlKeyDown)
		[self unmountVolume:theDesc];
	else
	{
		NTVolume* theVolume = [theDesc volume];
		NSArray* siblings = nil;
		BOOL optionKeyDown = [NSEvent optionKeyDownNow];
		
		if (!optionKeyDown)
			siblings = [NTPartitionInfo siblingEjectablePartitionsForVolume:theVolume];
		
		if ([siblings count])
		{
			NSString* titleFormat = [NTLocalizedString localize:@"The device containing \"%@\" also contains %d other volumes that will not be ejected. Are you sure you want to eject \"%@\"?"];
			
			if ([siblings count] == 1)
				titleFormat = [NTLocalizedString localize:@"The device containing \"%@\" also contains %d other volume that will not be ejected. Are you sure you want to eject \"%@\"?"];
			
			NSString* title = [NSString stringWithFormat:titleFormat, [[theVolume mountPoint] displayName], [siblings count], [[theVolume mountPoint] displayName]];
			
			NSString* message = [NTLocalizedString localize:@"To eject all the volumes on this device, click Eject All, or hold down the Option key while ejecting the volume."
			"\n\nIn the future, to eject a single volume without seeing this dialog, hold down the Control key while ejecting the volume."];
			
			[NTAlertPanel show:NSCriticalAlertStyle
						target:self 
					  selector:@selector(askEjectCallback:)
						 title:title
					   message:message
					   context:theDesc 
						window:nil
			defaultButtonTitle:[NTLocalizedString localize:@"Eject"]
		  alternateButtonTitle:[NTLocalizedString localize:@"Eject All"]
			  otherButtonTitle:[NTLocalizedString localize:@"Cancel"]
		  enableEscOnAlternate:NO
			  enableEscOnOther:YES
				   defaultsKey:nil];
		}
		else
			[self ejectVolume:theDesc];
	}
}

+ (void)unmountVolume:(NTFileDesc*)theDesc;
{	
	// calling unmount will unmount a volume, but not eject or park a firewire disk
    NTVolumeUnmounter* result = [[NTVolumeUnmounter alloc] init];
	
	result.desc = theDesc;

    // this object autoreleases itself when done
    [result doUnmountVolume];    
} 

+ (void)ejectVolume:(NTFileDesc*)theDesc;
{
    NTVolumeUnmounter* result = [[NTVolumeUnmounter alloc] init];
	
	result.desc = theDesc;
	
    // this object autoreleases itself when done
    [result doEjectVolume];
}

+ (void)askEjectCallback:(NTAlertPanel*)alertPanel;
{
	switch ([alertPanel resultCode])
	{
		case NSAlertFirstButtonReturn:
			[self unmountVolume:[alertPanel contextInfo]];
			break;
		case NSAlertSecondButtonReturn:
			[self ejectVolume:[alertPanel contextInfo]];
			break;
		case NSAlertThirdButtonReturn:
			// cancel
		default:
			break;
	}
}

@end

@implementation NTVolumeUnmounter (Private)

void volumeUnmountCallback(FSVolumeOperation volumeOp, void *clientData, OSStatus err, FSVolumeRefNum volumeRefNum, pid_t dissenter)
{
    NTVolumeUnmounter* theSelf = (NTVolumeUnmounter*)clientData;
	
    if (err != noErr)
    {
        NTFileDesc* volumeDesc = [theSelf desc];
        NSString *messageString = [NTMacErrorString macErrorString:err];
        NSString *errorString = [NTLocalizedString localize:@"Error: %d"];
		
        if (!messageString)
        {
            messageString = [NTLocalizedString localize:@"An error occurred while trying to unmount \"%@\"."];
            messageString = [NSString stringWithFormat:messageString, [volumeDesc displayName]];
        }
        
        errorString = [NSString stringWithFormat:errorString, err];
		
		// got a crash here, when the panel runs it's event loop, it calls some callback and randomly hangs
		// delay message for main event loop just to be safe
		NSArray *messages = [NSArray arrayWithObjects:messageString, errorString, nil];
		[theSelf performSelectorOnMainThread:@selector(displayErrorAfterDelay:) withObject:messages];
    }
    
    [theSelf autorelease];
}

void volumeEjectCallback(FSVolumeOperation volumeOp, void *clientData, OSStatus err, FSVolumeRefNum volumeRefNum, pid_t dissenter)
{
    NTVolumeUnmounter* theSelf = (NTVolumeUnmounter*)clientData;
    
    if (err != noErr)
    {
        NSString *messageString = [NTMacErrorString macErrorString:err];
        NSString *errorString = [NTLocalizedString localize:@"Error: %d"];
		
        if (!messageString)
        {
            NTFileDesc* volumeDesc = [theSelf desc];
			
            messageString = [NTLocalizedString localize:@"An error occurred while trying to eject \"%@\"."];
            messageString = [NSString stringWithFormat:messageString, [volumeDesc displayName]];
        }
        
        errorString = [NSString stringWithFormat:errorString, err];
        
		// got a crash here, when the panel runs it's event loop, it calls some callback and randomly hangs
		// delay message for main event loop just to be safe
		NSArray *messages = [NSArray arrayWithObjects:messageString, errorString, nil];
        [theSelf performSelectorOnMainThread:@selector(displayErrorAfterDelay:) withObject:messages];
    }
    
    [theSelf autorelease];
}

- (void)displayErrorAfterDelay:(id)object;
{
	NSString* messageString=@"";
	NSString* errorString=@"";
	
	if ([object isKindOfClass:[NSArray class]])
	{
		if ([object count])
			messageString = [object objectAtIndex:0];
		
		if ([object count] > 1)
			errorString = [object objectAtIndex:1];
	}
	
	[NTSimpleAlert alertPanel:messageString subMessage:errorString];
}

- (void)doUnmountVolume;
{
    OSStatus err;
        
    self.unmountUPP = NewFSVolumeUnmountUPP(volumeUnmountCallback);
    
    err = FSUnmountVolumeAsync([self.desc volumeRefNum], 0, self.volumeOp, self, self.unmountUPP, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
	
	if (err)
		NSLog(@"FSUnmountVolumeAsync err:%d", err);
}

- (void)doEjectVolume;
{
    OSStatus err;
        
    self.ejectUPP = NewFSVolumeEjectUPP(volumeEjectCallback);
    
    err = FSEjectVolumeAsync([self.desc volumeRefNum], 0, self.volumeOp, self, self.ejectUPP, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
	
	if (err)
		NSLog(@"FSEjectVolumeAsync err:%d", err);
}

@end
