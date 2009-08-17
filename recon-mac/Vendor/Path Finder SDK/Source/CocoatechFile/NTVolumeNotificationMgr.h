//
//  NTVolumeNotificationMgr.h

#import <Cocoa/Cocoa.h>

@class NTVolume, NTFileDesc, NTFSWatcher;

// when our list of volumes has changed
#define kNTVolumeMgrVolumeListHasChangedNotification @"kNTVolumeMgrVolumeListHasChangedNotification"

// a volume has mounted or unmounted - list is up to date
#define kNTVolumeMgrVolumeHasMountedNotification @"kNTVolumeMgrVolumeHasMountedNotification"

// userInfo of the dictionary for kNTVolumeMgrVolumeHasMountedNotification
#define kMountEventArrayKey @"kMountEventArrayKey"    // an array of dictionaries
#define kMountEventKey @"mountEventKey"
#define kMountEvent @"mountEvent"
#define kUnMountEvent @"unmountEvent"

@interface NTVolumeNotificationMgr : NTSingletonObject
{
    BOOL sendingDelayedNotifications;
	
	NTFSWatcher* mv_fsWatcher;	
    NSMutableDictionary *notificationDictionary;
}

@property (assign) BOOL sendingDelayedNotifications;
@property (retain) NSMutableDictionary *notificationDictionary;

- (void)manuallyRefresh;

@end

