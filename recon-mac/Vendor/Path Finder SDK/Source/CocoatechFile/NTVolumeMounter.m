//
//  NTVolumeMounter.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Tue Sep 03 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import "NTVolumeMounter.h"

@interface NTVolumeMounter (Private)
- (void)doMountVolumeWithURL:(NSURL*)url user:(NSString*)user password:(NSString*)password notifyWhenMounts:(NSString*)notificationName;
- (NTFileDesc*)volumeForURL:(NSURL*)url;
- (void)setVolume:(NTFileDesc*)volumeDesc forURL:(NSURL*)url;
@end

@implementation NTVolumeMounter

@synthesize url;
@synthesize notificationName;

- (id)init;
{
    self = [super init];
    
    FSCreateVolumeOperation(&_volumeOp);

    return self;
}

- (void)dealloc;
{
    FSDisposeVolumeOperation(_volumeOp);

    if (_mountUPP)
        DisposeFSVolumeMountUPP(_mountUPP);

    self.url = nil;
    self.notificationName = nil;
    
    [super dealloc];
}

+ (void)mountVolumeWithURL:(NSURL*)url user:(NSString*)user password:(NSString*)password notifyWhenMounts:(NSString*)notificationName;
{
    NTVolumeMounter* result = [[NTVolumeMounter alloc] init];
    
    // this object autoreleases itself when done
    [result doMountVolumeWithURL:url user:user password:password notifyWhenMounts:notificationName];
}

+ (void)mountVolumeWithScheme:(NSString*)scheme host:(NSString*)host path:(NSString*)path user:(NSString*)user password:(NSString*)password notifyWhenMounts:(NSString*)notificationName;
{
    NSString* urlString;

    if (path && [path length])
        urlString = [NSString stringWithFormat:@"%@://%@/%@", scheme, host, path];
    else
        urlString = [NSString stringWithFormat:@"%@://%@", scheme, host];

    @try {
        [NTVolumeMounter mountVolumeWithURL:[[[NSURL alloc] initWithString:urlString] autorelease] user:user password:password notifyWhenMounts:notificationName];
	}
	@catch (NSException * e) {
	}
	@finally {
	}
}
    
@end

@implementation NTVolumeMounter (Private)

void volumeMountCallback(FSVolumeOperation volumeOp, void *clientData, OSStatus err, FSVolumeRefNum mountedVolumeRefNum)
{
    NTVolumeMounter* mounter = (NTVolumeMounter*)clientData;
    NTFileDesc *volumeDesc=nil;
    
    if (err != noErr)
    {
        // this error comes up when the volume is already mounted
        if (err == volOnLinErr)
        {
            volumeDesc = [mounter volumeForURL:[mounter url]];

            if (volumeDesc && [volumeDesc isValid])
            {
                if ([[mounter notificationName] length])
                    [[NSNotificationCenter defaultCenter] postNotificationName:[mounter notificationName] object:volumeDesc userInfo:nil];
            }
        }
        else if (err == userCanceledErr)
			; // user canceled, don't warn user
		else
        {
            NSString *messageString = [NTLocalizedString localize:@"An error occurred while trying to mount \"%@\"."];
            NSString *errorString = [NTLocalizedString localize:@"Error: %d"];

            messageString = [NSString stringWithFormat:messageString, [mounter url]];
            errorString = [NSString stringWithFormat:errorString, err];

			// got a crash here, when the panel runs it's event loop, it calls some callback and randomly hangs
			// delay message for main event loop just to be safe
			// NSArray *messages = [NSArray arrayWithObjects:messageString, errorString, nil];
			// [mounter performSelectorOnMainThread:@selector(displayErrorAfterDelay:) withObject:messages];
			
			NSLog(@"%@, err: %@", messageString, errorString);
        }
    }
    else if ([[mounter notificationName] length] && mountedVolumeRefNum != 0)
    {
        volumeDesc = [NTFileDesc descVolumeRefNum:mountedVolumeRefNum];

        if (volumeDesc && [volumeDesc isValid])
        {
            [mounter setVolume:volumeDesc forURL:[mounter url]];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:[mounter notificationName] object:volumeDesc userInfo:nil];
        }
    }
    
    [mounter autorelease];
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

- (void)doMountVolumeWithURL:(NSURL*)theURL user:(NSString*)user password:(NSString*)password notifyWhenMounts:(NSString*)theNotificationName;
{
    OSStatus err;
    CFStringRef userRef=nil, passRef=nil;
	
    self.url = theURL;
    self.notificationName = theNotificationName;
	
    // if no user name given, user the login name
    if (!user || ![user length])
        user = NSUserName();
	
    if (![self.url user])
    {
		if (user && [user length])
			userRef = (CFStringRef)user;
    }

    if (![self.url password])
    {
		// don't pass in nil for password, otherwise the name passed in doesn't get used ("public" for public iDisk for example)
        if (password)
            passRef = (CFStringRef)password;
    }
        
    _mountUPP = NewFSVolumeMountUPP(volumeMountCallback);
	
	// was getting a kernel panic and some strange stuff here
	// I'm assuming it might have something to do with the strings being autoreleased, so I added this retain and release around this call
	if (passRef)
		CFRetain(passRef);
	if (userRef)
		CFRetain(userRef);
	
	err = FSMountServerVolumeAsync((CFURLRef)self.url, (CFURLRef)NULL, NULL, NULL, _volumeOp, self, 0, _mountUPP, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	
	if (err)
		NSLogErr(@"FSMountServerVolumeAsync", err);
		
	if (passRef)
		CFRelease(passRef);
	if (userRef)
		CFRelease(userRef);	
}

static NSMutableDictionary *sVolumeURLDictionary=nil;

- (NTFileDesc*)volumeForURL:(NSURL*)theUrl;
{
    NTFileDesc* result = nil;
    
    if (sVolumeURLDictionary)
    {
        NSString* path = [sVolumeURLDictionary objectForKey:theUrl];

        if (path)
        {
            result = [NTFileDesc descNoResolve:path];

            if (![result isValid])
                result = nil;   // it's autoreleased, so nil is fine
        }
    }

    return result;
}

- (void)setVolume:(NTFileDesc*)volumeDesc forURL:(NSURL*)theURL;
{
    if (!sVolumeURLDictionary)
        sVolumeURLDictionary = [[NSMutableDictionary alloc] init];

    [sVolumeURLDictionary setObject:[volumeDesc path] forKey:theURL];
}

@end
