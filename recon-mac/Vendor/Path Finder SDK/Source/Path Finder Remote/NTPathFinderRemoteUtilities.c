//
//  NTPathFinderRemoteUtilities.m
//  Path Finder Remote
//
//  Created by Steve Gehrman on 4/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#include "NTPathFinderRemoteUtilities.h"

// global FSRef.  Only want to search for it once
FSRef pathFinderFSRef;

#define kPathFinderPreferenceID		CFSTR("com.cocoatech.PathFinder")
#define kRevealInPathFinderEnabledPreferenceKey		CFSTR("kRevealInPathFinderEnabledPreferenceKey")
#define kPathFinderSignature 'PFdR'

Boolean sendRevealEvent(const FSRef * fsRef);
Boolean pathFinderRunningRef(FSRef* outRef, ProcessInfoRec* outProcessInfo);

CFStringRef revealInPathFinderLocalizedString()
{
	CFStringRef result=nil;
	CFStringRef key = CFSTR("Reveal in Path Finder");
	CFBundleRef bundle = CFBundleGetBundleWithIdentifier(CFSTR("com.cocoatech.PathFinderRemote"));
	
	if (bundle)
		result = CFBundleCopyLocalizedString(bundle, key, key, NULL);
	
	return result;
}		

Boolean isPathFinderRunning()
{
    if (!pathFinderRunningRef(nil, nil))
		return true;
	
	return false;
}

// third party apps can use this to determine if they should pass reveal appleevents to Path Finder
// the preferece is set in Path Finders preference panel
Boolean revealInPathFinderPreferenceEnabled()
{
	Boolean result;
	
	CFPreferencesAppSynchronize(kPathFinderPreferenceID);

	if (CFPreferencesGetAppBooleanValue(kRevealInPathFinderEnabledPreferenceKey, kPathFinderPreferenceID, &result))
		return result;
	
	return false;
}

void setRevealInPathFinderPreferenceEnabled(Boolean set)
{
	CFPreferencesSetAppValue(kRevealInPathFinderEnabledPreferenceKey, set ? kCFBooleanTrue : kCFBooleanFalse, kPathFinderPreferenceID);
	
	CFPreferencesAppSynchronize(kPathFinderPreferenceID);
}

// sends a reveal event the old fashion way
void revealInPathFinderUsingAppleEvent(FSRef *ref)
{
	launchPathFinder();
	
	if (sendRevealEvent(ref))
		activatePathFinder();
}

Boolean pathFinderIsCurrentApplication()
{
    ProcessSerialNumber PSN = {kNoProcess, kNoProcess};

    if (MacGetCurrentProcess(&PSN) == noErr)
    {
        ProcessInfoRec info;
        Str255 name;
        FSSpec spec;
        OSErr err;
        
        info.processInfoLength = sizeof(ProcessInfoRec);
        info.processName = name;
        info.processAppSpec = &spec;

        err = GetProcessInformation(&PSN, &info);
        if (err == noErr && !(info.processMode & modeOnlyBackground))
        {
            if (info.processSignature == kPathFinderSignature)
                return true;
        }
    }
    
    return false;
}

void activatePathFinder()
{
    if (!pathFinderIsCurrentApplication())
    {
        ProcessInfoRec info;

        if (pathFinderRunningRef(nil, &info))
            SetFrontProcessWithOptions(&info.processNumber, kSetFrontProcessFrontWindowOnly);
    }
}

Boolean pathFinderApplicationRef(FSRef* outRef)
{
    Boolean result = false;
    OSStatus err;

    // first make sure our pathFinderFSRef is valid, if valid, return it
    err = FSGetCatalogInfo(&pathFinderFSRef, kFSCatInfoNone, nil, nil, nil, nil);
    if (err == noErr)
        result = true;

    if (!result)
        result = pathFinderRunningRef(&pathFinderFSRef, nil);

    if (!result)
    {
        err = FSPathMakeRef((UInt8*)"/Applications/Path Finder.app", &pathFinderFSRef, nil);
        if (err == noErr)
            result = true;
    }

    if (!result)
    {
        // this routine seems to search the whole home folder first, then look in the apps folder
        err = LSFindApplicationForInfo(kPathFinderSignature, NULL, NULL, &pathFinderFSRef, NULL);
        if (err == noErr)
            result = true;
    }

    if (result)
        *outRef = pathFinderFSRef;

    return result;
}

// if Path Finder is not running, launch it
void launchPathFinder()
{    
    // is path finder not running?
    if (!pathFinderRunningRef(nil, nil))
    {
        FSRef appRef;
        Boolean appFound = pathFinderApplicationRef(&appRef);

        if (appFound)
            LSOpenFSRef(&appRef, nil);
    }
}

Boolean sendRevealEvent(const FSRef * fsRef)
{
    AEDesc       targetAddress;
    AppleEvent   ae;
    AppleEvent   reply;
    OSType       appSignature = kPathFinderSignature;
    AliasHandle       alias = 0;
    OSErr        err;

    AEInitializeDesc(&targetAddress);
    AEInitializeDesc(&ae);
    AEInitializeDesc(&reply);

    // create a target address for the Finder
    err = AECreateDesc(typeApplSignature, &appSignature,
                       sizeof(appSignature),
                       &targetAddress);

    // create a "reveal" Apple event
    err = AECreateAppleEvent(kAEMiscStandards, kAEMakeObjectsVisible,
                             &targetAddress, kAutoGenerateReturnID, kAnyTransactionID, &ae);

    // add direct parameter
    err = FSNewAliasMinimal(fsRef, &alias);
    HLock((Handle) alias);
    err = AEPutParamPtr(&ae, keyDirectObject, typeAlias, *alias,
                        GetHandleSize((Handle)alias));
    HUnlock((Handle)alias);

    // send the event
    err = AESend(&ae, &reply, kAENoReply | kAECanSwitchLayer,
                 kAENormalPriority,
                 kAEDefaultTimeout, 0, 0);

    // clean up
    DisposeHandle((Handle)alias);
    AEDisposeDesc(&targetAddress);
    AEDisposeDesc(&ae);
    AEDisposeDesc(&reply);

    return (err == noErr);
}

Boolean pathFinderRunningRef(FSRef* outRef, ProcessInfoRec* outProcessInfo)
{
    ProcessSerialNumber PSN = {kNoProcess, kNoProcess};
    OSErr err;
    int i;
    Boolean result = false;
    
    // arbitrary limit of 200, I just want to avoid an endless loop if there is some strange bug in Carbon
    for (i=0;i<200;i++)
    {
        err = GetNextProcess(&PSN);
		
        if (err == noErr)
        {
            ProcessInfoRec info;
            Str255 name;
            FSSpec spec;
            
            info.processInfoLength = sizeof(ProcessInfoRec);
            info.processName = name;
            info.processAppSpec = &spec;
			
            err = GetProcessInformation(&PSN, &info);
            if (err == noErr && !(info.processMode & modeOnlyBackground))
            {
                if (info.processSignature == kPathFinderSignature)
                {
                    result = true;
					
                    if (outRef)
                        err = GetProcessBundleLocation(&PSN,outRef);
					
                    if (outProcessInfo)
                        *outProcessInfo = info;
					
                    break;
                }
            }
        }
		
        if (result)
            break;
    }
	
    return result;
}
