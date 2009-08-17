//
//  NTDefaultDirectory.m
//  CocoatechFile
//
//  Created by sgehrman on Tue Jun 05 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NTDefaultDirectory.h"
#import "NTPathUtilities.h"
#import <sys/stat.h>
#import <sys/fcntl.h>
#import "NTFileCreation.h"

@interface NTDefaultDirectory (Private)
- (NSString *)findSystemFolderType:(int)folderType forDomain:(int)domain createFolder:(BOOL)createFolder;
@end

@interface NTDefaultDirectory (hidden)
- (void)setUtilitiesPath:(NSString *)theUtilitiesPath;
- (void)setDownloadsPath:(NSString *)theDownloadsPath;
@end

#define kPluginsFolderName @"PlugIns"  // this matches NSBundle
#define kSettingsFolderName @"Settings"
#define kCoreDataFolderName @"Core Data"

@implementation NTDefaultDirectory

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

@synthesize savedSearchesPath;

+ (NTDefaultDirectory*)sharedInstance;
{
	return [super sharedInstance];
}

- (void)dealloc;
{
	self.savedSearchesPath = nil;
    [_homePath release];
    [_favoritesPath release];
    [_trashPath release];
    [_userLibraryPath release];
    [_userContextualMenuItemsPath release];
    [_contextualMenuItemsPath release];
    [_userApplicationsPath release];
    [_desktopPath release];
    [_documentsPath release];
    [_musicPath release];
    [_moviesPath release];
    [_picturesPath release];
    [_sitesPath release];
    [_publicPath release];
	[_userLogsPath release];
    [_userPreferencesPath release];
    [_recentServersPath release];
	[_desktopPicturesPath release];
    [mv_applicationDirectories release];
	[self setUtilitiesPath:nil];

    [_computerPath release];
    [_rootPath release];
    [_systemPath release];
    [_usersPath release];
    [_libraryPath release];
    [_applicationsPath release];
    [_classicApplicationsPath release];
    [_developerApplicationsPath release];
    [_networkApplicationsPath release];
    [_tmpPath release];
	[_varlogPath release];
	[_logsPath release];
	[_consoleLogsPath release];
	
	[_userApplicationSupportPath release];
    [_userApplicationSupportApplicationPath release];
    [_applicationSupportPath release];
    [_applicationSupportApplicationPath release];
    [_applicationSupportPluginsPath release];	
	[_userApplicationSupportPluginsPath release];
	[_userApplicationSupportPluginSupportPath release];
	[_userApplicationSupportSettingsPath release];
	[_userApplicationSupportCoreDataPath release];
	
    [_userPreferencePanesPath release];
    [_preferencePanesPath release];
    [_systemPreferencePanesPath release];

    [_userInputManagersPath release];
    [_inputManagersPath release];
	[self setDownloadsPath:nil];

    [super dealloc];
}

// home directories
- (NSString*)homePath;
{
    if (!_homePath)
    {
        _homePath = NSHomeDirectory();

        [_homePath retain];
    }

    return _homePath;
}

- (NSString*)favoritesPath;
{
    if (!_favoritesPath)
        _favoritesPath = [[self findSystemFolderType:kFavoritesFolderType forDomain:kUserDomain createFolder:YES] retain];

    return _favoritesPath;
}

- (NSString*)trashPath;
{
    if (!_trashPath)
		_trashPath = [[self findSystemFolderType:kTrashFolderType forDomain:kUserDomain createFolder:YES] retain];

    return _trashPath;
}

- (NSString*)trashPathForDesc:(NTFileDesc*)desc create:(BOOL)create;
{	
	return [self findSystemFolderType:kTrashFolderType forDomain:[desc volumeRefNum] createFolder:create];
}

- (NSString*)userLibraryPath;
{
    if (!_userLibraryPath)
        _userLibraryPath = [[self findSystemFolderType:kDomainLibraryFolderType forDomain:kUserDomain createFolder:NO] retain];

    return _userLibraryPath;
}

- (NSString*)userContextualMenuItemsPath;
{
    if (!_userContextualMenuItemsPath)
        _userContextualMenuItemsPath = [[self findSystemFolderType:kContextualMenuItemsFolderType forDomain:kUserDomain createFolder:YES] retain];
    
    return _userContextualMenuItemsPath;
}

- (NSString*)contextualMenuItemsPath;
{
    if (!_contextualMenuItemsPath)
        _contextualMenuItemsPath = [[self findSystemFolderType:kContextualMenuItemsFolderType forDomain:kLocalDomain  createFolder:YES] retain];
    
    return _contextualMenuItemsPath;
}

- (NSString*)userApplicationsPath;
{
    if (!_userApplicationsPath)
        _userApplicationsPath = [[self findSystemFolderType:kApplicationsFolderType forDomain:kUserDomain createFolder:NO] retain];

    return _userApplicationsPath;
}

- (NSString*)desktopPath;
{
    if (!_desktopPath)
        _desktopPath = [[self findSystemFolderType:kDesktopFolderType forDomain:kUserDomain createFolder:NO] retain];

    return _desktopPath;
}

- (NSString*)documentsPath;
{
    if (!_documentsPath)
        _documentsPath = [[self findSystemFolderType:kDocumentsFolderType forDomain:kUserDomain createFolder:YES] retain];

    return _documentsPath;
}

- (NSString*)musicPath;
{
    if (!_musicPath)
        _musicPath = [[self findSystemFolderType:kMusicDocumentsFolderType forDomain:kUserDomain createFolder:NO] retain];

    return _musicPath;
}

- (NSString*)moviesPath;
{
    if (!_moviesPath)
        _moviesPath = [[self findSystemFolderType:kMovieDocumentsFolderType forDomain:kUserDomain createFolder:NO] retain];

    return _moviesPath;
}

- (NSString*)picturesPath;
{
    if (!_picturesPath)
        _picturesPath = [[self findSystemFolderType:kPictureDocumentsFolderType forDomain:kUserDomain createFolder:NO] retain];

    return _picturesPath;
}

- (NSString*)sitesPath;
{
    if (!_sitesPath)
        _sitesPath = [[self findSystemFolderType:kInternetSitesFolderType forDomain:kUserDomain createFolder:NO] retain];

    return _sitesPath;
}

- (NSString*)publicPath;
{
    if (!_publicPath)
        _publicPath = [[self findSystemFolderType:kPublicFolderType forDomain:kUserDomain createFolder:NO] retain];

    return _publicPath;
}

- (NSString*)userLogsPath;
{
	if (!_userLogsPath)
        _userLogsPath = [[self findSystemFolderType:kLogsFolderType forDomain:kUserDomain createFolder:NO] retain];
	
	return _userLogsPath;
}

- (NSString*)recentServersPath;
{
    if (!_recentServersPath)
		_recentServersPath = [[self findSystemFolderType:kRecentServersFolderType forDomain:kUserDomain createFolder:YES] retain];
    
    return _recentServersPath;
}

- (NSString*)desktopPicturesPath;
{
	if (!_desktopPicturesPath)
		_desktopPicturesPath = [[self findSystemFolderType:kDesktopPicturesFolderType forDomain:kLocalDomain createFolder:NO] retain];
    
    return _desktopPicturesPath;
}

- (NSString*)computerPath;
{
    if (!_computerPath)
    {
        _computerPath = @"";
        
        [_computerPath retain];
    }
    
    return _computerPath;
}

- (NSString*)rootPath;
{
    if (!_rootPath)
    {
        _rootPath = NSOpenStepRootDirectory(); // should just be @"/"

        [_rootPath retain];
    }

    return _rootPath;
}

- (NSString*)systemPath;
{
    if (!_systemPath)
        _systemPath = [[self findSystemFolderType:kSystemFolderType forDomain:kLocalDomain createFolder:NO] retain];

    return _systemPath;
}

- (NSString*)usersPath;
{
    if (!_usersPath)
        _usersPath = [[self findSystemFolderType:kUsersFolderType forDomain:kLocalDomain createFolder:NO] retain];

    return _usersPath;
}

- (NSString*)libraryPath;
{
    if (!_libraryPath)
        _libraryPath = [[self findSystemFolderType:kDomainLibraryFolderType forDomain:kLocalDomain createFolder:NO] retain];

    return _libraryPath;
}

- (NSString*)applicationsPath;
{
    if (!_applicationsPath)
        _applicationsPath = [[self findSystemFolderType:kApplicationsFolderType forDomain:kLocalDomain createFolder:YES] retain];

    return _applicationsPath;
}

//---------------------------------------------------------- 
//  utilitiesPath 
//---------------------------------------------------------- 
- (NSString *)utilitiesPath
{
	if (!mUtilitiesPath)
		[self setUtilitiesPath:[self findSystemFolderType:kUtilitiesFolderType forDomain:kLocalDomain createFolder:YES]];
	
	return mUtilitiesPath; 
}

- (void)setUtilitiesPath:(NSString *)theUtilitiesPath
{
    if (mUtilitiesPath != theUtilitiesPath)
    {
        [mUtilitiesPath release];
        mUtilitiesPath = [theUtilitiesPath retain];
    }
}

- (NSString*)classicApplicationsPath;
{
    if (!_classicApplicationsPath)
    {
        _classicApplicationsPath = @"/";
        _classicApplicationsPath = [_classicApplicationsPath stringByAppendingPathComponent:@"Applications (Mac OS 9)"];

        [_classicApplicationsPath retain];
    }

    return _classicApplicationsPath;
}

- (NSString*)developerApplicationsPath;
{
    if (!_developerApplicationsPath)
	{
		// kLocalDomain returned nil
		_developerApplicationsPath = [[self findSystemFolderType:kDeveloperApplicationsFolderType forDomain:kSystemDomain createFolder:NO] retain];
	}
	
    return _developerApplicationsPath;
}

- (NSString*)networkApplicationsPath;
{
    if (!_networkApplicationsPath)
        _networkApplicationsPath = [[self findSystemFolderType:kApplicationsFolderType forDomain:kNetworkDomain createFolder:NO] retain];

    return _networkApplicationsPath;
}

- (NSString*)tmpPath;
{
    if (!_tmpPath)
    {
        _tmpPath = NSTemporaryDirectory();
		
        [_tmpPath retain];
    }
	
    return _tmpPath;
}

- (NSString*)varlogPath;
{
    if (!_varlogPath)
    {
        _varlogPath = @"/var/log";
		
        [_varlogPath retain];
    }
	
    return _varlogPath;
}

- (NSString*)logsPath;
{
    if (!_logsPath)
        _logsPath = [[self findSystemFolderType:kLogsFolderType forDomain:kLocalDomain createFolder:NO] retain];
	
    return _logsPath;
}

- (NSString*)consoleLogsPath;
{
    if (!_consoleLogsPath)
    {
        _consoleLogsPath = [self logsPath];
		_consoleLogsPath = [_consoleLogsPath stringByAppendingPathComponent:@"Console"];
		
        [_consoleLogsPath retain];
    }
	
    return _consoleLogsPath;
}

- (NSString*)preferencePanesPath;
{
    if (!_preferencePanesPath)
        _preferencePanesPath = [[self findSystemFolderType:kPreferencePanesFolderType forDomain:kLocalDomain createFolder:NO] retain];
    
    return _preferencePanesPath;
}

- (NSString*)systemPreferencePanesPath;
{
    if (!_systemPreferencePanesPath)
        _systemPreferencePanesPath = [[self findSystemFolderType:kPreferencePanesFolderType forDomain:kLocalDomain createFolder:NO] retain];
    
    return _systemPreferencePanesPath;
}

- (NSString*)userPreferencePanesPath;
{
    if (!_userPreferencePanesPath)
        _userPreferencePanesPath = [[self findSystemFolderType:kPreferencePanesFolderType forDomain:kUserDomain createFolder:NO] retain];
    
    return _userPreferencePanesPath;
}

- (NSString*)userApplicationSupportPath;
{
    if (!_userApplicationSupportPath)
        _userApplicationSupportPath = [[self findSystemFolderType:kApplicationSupportFolderType forDomain:kUserDomain createFolder:YES] retain];

    return _userApplicationSupportPath;
}

- (NSString*)userApplicationSupportApplicationPath;
{
    if (!_userApplicationSupportApplicationPath)
    {
        _userApplicationSupportApplicationPath = [[[self userApplicationSupportPath] stringByAppendingPathComponent:[NTUtilities applicationName]] retain];
        
        // create folder if doesn't exist
        if (![NTPathUtilities pathOK:_userApplicationSupportApplicationPath])
            [NTFileCreation newFolder:_userApplicationSupportApplicationPath permissions:0];
    }
    
    return _userApplicationSupportApplicationPath;
}

- (NSString*)applicationSupportPath;
{
    if (!_applicationSupportPath)
        _applicationSupportPath = [[self findSystemFolderType:kApplicationSupportFolderType forDomain:kLocalDomain createFolder:YES] retain];
    
    return _applicationSupportPath;
}

- (NSString*)applicationSupportApplicationPath;
{
    if (!_applicationSupportApplicationPath)
    {
        _applicationSupportApplicationPath = [[[self applicationSupportPath] stringByAppendingPathComponent:[NTUtilities applicationName]] retain];
        
        // create folder if doesn't exist
        if (![NTPathUtilities pathOK:_applicationSupportApplicationPath])
            [NTFileCreation newFolder:_applicationSupportApplicationPath permissions:0];
    }
    
    return _applicationSupportApplicationPath;
}

- (NSString*)userPreferencesPath;
{
    if (!_userPreferencesPath)
        _userPreferencesPath = [[self findSystemFolderType:kPreferencesFolderType forDomain:kUserDomain createFolder:YES] retain];

    return _userPreferencesPath;
}

- (NSString*)userApplicationSupportPluginsPath;
{
    if (!_userApplicationSupportPluginsPath)
    {
        _userApplicationSupportPluginsPath = [[self userApplicationSupportApplicationPath] stringByAppendingPathComponent:kPluginsFolderName];
        
        // create folder if doesn't exist
        if (![NTPathUtilities pathOK:_userApplicationSupportPluginsPath])
            [NTFileCreation newFolder:_userApplicationSupportPluginsPath permissions:0];
        
        [_userApplicationSupportPluginsPath retain];
    }
    
    return _userApplicationSupportPluginsPath;
}

- (NSString*)userApplicationSupportSettingsPath;
{
    if (!_userApplicationSupportSettingsPath)
    {
        _userApplicationSupportSettingsPath = [[self userApplicationSupportApplicationPath] stringByAppendingPathComponent:kSettingsFolderName];
        
        // create folder if doesn't exist
        if (![NTPathUtilities pathOK:_userApplicationSupportSettingsPath])
            [NTFileCreation newFolder:_userApplicationSupportSettingsPath permissions:0];
        
        [_userApplicationSupportSettingsPath retain];
    }
    
    return _userApplicationSupportSettingsPath;
}

- (NSString*)userApplicationSupportCoreDataPath;
{
    if (!_userApplicationSupportCoreDataPath)
    {
        _userApplicationSupportCoreDataPath = [[self userApplicationSupportApplicationPath] stringByAppendingPathComponent:kCoreDataFolderName];
        
        // create folder if doesn't exist
        if (![NTPathUtilities pathOK:_userApplicationSupportCoreDataPath])
            [NTFileCreation newFolder:_userApplicationSupportCoreDataPath permissions:0];
        
        [_userApplicationSupportCoreDataPath retain];
    }
    
    return _userApplicationSupportCoreDataPath;
}

- (NSString*)applicationSupportPluginsPath;
{
    if (!_applicationSupportPluginsPath)
    {
        _applicationSupportPluginsPath = [[self applicationSupportApplicationPath] stringByAppendingPathComponent:kPluginsFolderName];
        
        // create folder if doesn't exist
        if (![NTPathUtilities pathOK:_applicationSupportPluginsPath])
            [NTFileCreation newFolder:_applicationSupportPluginsPath permissions:0];
        
        [_applicationSupportPluginsPath retain];
    }
    
    return _applicationSupportPluginsPath;
}

- (NSString*)userApplicationSupportPluginSupportPath;
{
    if (!_userApplicationSupportPluginSupportPath)
    {
        _userApplicationSupportPluginSupportPath = [[self userApplicationSupportApplicationPath] stringByAppendingPathComponent:@"PlugIn Support"];
        
        // create folder if doesn't exist
        if (![NTPathUtilities pathOK:_userApplicationSupportPluginSupportPath])
            [NTFileCreation newFolder:_userApplicationSupportPluginSupportPath permissions:0];
        
        [_userApplicationSupportPluginSupportPath retain];
    }
    
    return _userApplicationSupportPluginSupportPath;
}

- (NSString*)userInputManagersPath;
{
    if (!_userInputManagersPath)
    {
        _userInputManagersPath = [[self userLibraryPath] stringByAppendingPathComponent:@"InputManagers"];
        
        // create folder if doesn't exist
        if (![NTPathUtilities pathOK:_userInputManagersPath])
            [NTFileCreation newFolder:_userInputManagersPath permissions:0];
        
        [_userInputManagersPath retain];
    }
    
    return _userInputManagersPath;
}

// overridden to lazily create
- (NSString *)savedSearchesPath
{
	if (!savedSearchesPath)	
	{
		self.savedSearchesPath = [[self userLibraryPath] stringByAppendingPathComponent:@"Saved Searches"];
		
		// create folder if doesn't exist
        if (![NTPathUtilities pathOK:savedSearchesPath])
            [NTFileCreation newFolder:savedSearchesPath permissions:0];
	}
	
	return savedSearchesPath; 
}
	
//---------------------------------------------------------- 
//  downloadsPath 
//---------------------------------------------------------- 
- (NSString *)downloadsPath
{
	if (!mDownloadsPath)		
		[self setDownloadsPath:[[self homePath] stringByAppendingPathComponent:@"Downloads"]];
	
	return mDownloadsPath; 
}

- (void)setDownloadsPath:(NSString *)theDownloadsPath
{
    if (mDownloadsPath != theDownloadsPath)
    {
        [mDownloadsPath release];
        mDownloadsPath = [theDownloadsPath retain];
    }
}

- (NSString*)inputManagersPath;
{
    if (!_inputManagersPath)
    {
        _inputManagersPath = [[self libraryPath] stringByAppendingPathComponent:@"InputManagers"];
        
        // create folder if doesn't exist
        if (![NTPathUtilities pathOK:_inputManagersPath])
            [NTFileCreation newFolder:_inputManagersPath permissions:0];
        
        [_inputManagersPath retain];
    }
    
    return _inputManagersPath;    
}

// =============================================================================

- (NTFileDesc*)favorites
{
    return [NTFileDesc descResolve:[self favoritesPath]];
}

- (NTFileDesc*)userLibrary;
{
    return [NTFileDesc descResolve:[self userLibraryPath]];
}

- (NTFileDesc*)contextualMenuItems;
{
    return [NTFileDesc descResolve:[self contextualMenuItemsPath]];
}

- (NTFileDesc*)userContextualMenuItems;
{
    return [NTFileDesc descResolve:[self userContextualMenuItemsPath]];
}

- (NTFileDesc*)trash
{
    return [NTFileDesc descResolve:[self trashPath]];
}

- (NTFileDesc*)root
{
    return [NTFileDesc descResolve:[self rootPath]];
}

- (NTFileDesc*)library;
{
    return [NTFileDesc descResolve:[self libraryPath]];
}

- (NTFileDesc*)users;
{
    return [NTFileDesc descResolve:[self usersPath]];
}

- (NTFileDesc*)system;
{
    return [NTFileDesc descResolve:[self systemPath]];
}

- (NTFileDesc*)home
{
    return [NTFileDesc descResolve:[self homePath]];
}

- (NTFileDesc*)applications
{
    return [NTFileDesc descResolve:[self applicationsPath]];
}

- (NTFileDesc*)utilities;
{
	return [NTFileDesc descResolve:[self utilitiesPath]];
}

- (NTFileDesc*)classicApplications
{
    return [NTFileDesc descResolve:[self classicApplicationsPath]];
}

- (NTFileDesc*)developerApplications
{
    return [NTFileDesc descResolve:[self developerApplicationsPath]];
}

- (NTFileDesc*)networkApplications
{
    return [NTFileDesc descResolve:[self networkApplicationsPath]];
}

- (NTFileDesc*)userApplications
{
    return [NTFileDesc descResolve:[self userApplicationsPath]];
}

- (NTFileDesc*)desktop
{
    return [NTFileDesc descResolve:[self desktopPath]];
}

- (NTFileDesc*)documents
{
    return [NTFileDesc descResolve:[self documentsPath]];
}

- (NTFileDesc*)music
{
    return [NTFileDesc descResolve:[self musicPath]];
}

- (NTFileDesc*)movies
{
    return [NTFileDesc descResolve:[self moviesPath]];
}

- (NTFileDesc*)pictures
{
    return [NTFileDesc descResolve:[self picturesPath]];
}

- (NTFileDesc*)sites
{
    return [NTFileDesc descResolve:[self sitesPath]];
}

- (NTFileDesc*)public
{
    return [NTFileDesc descResolve:[self publicPath]];
}

- (NTFileDesc*)recentServers;
{
    return [NTFileDesc descResolve:[self recentServersPath]];
}

- (NTFileDesc*)desktopPictures;
{
	return [NTFileDesc descResolve:[self desktopPicturesPath]];
}

- (NTFileDesc*)computer
{
    return [NTFileDesc descNoResolve:[self computerPath]];
}

- (NTFileDesc*)tmp;
{
    return [NTFileDesc descResolve:[self tmpPath]];
}

- (NTFileDesc*)varlog;
{
    return [NTFileDesc descResolve:[self varlogPath]];
}

- (NTFileDesc*)logs;
{
    return [NTFileDesc descResolve:[self logsPath]];
}

- (NTFileDesc *)savedSearches;
{
	return [NTFileDesc descResolve:[self savedSearchesPath]];
}

- (NTFileDesc*)userLogs;
{
	return [NTFileDesc descResolve:[self userLogsPath]];
}

- (NSArray*)applicationDirectories;
{
	if (!mv_applicationDirectories)
	{
		NSMutableArray* result = [NSMutableArray array];
		
		if ([[self applications] isValid])
			[result addObject:[self applications]];
		
		if ([[self userApplications] isValid])
			[result addObject:[self userApplications]];
				
		if ([[self developerApplications] isValid])
			[result addObject:[self developerApplications]];
		
		if ([[self classicApplications] isValid])
			[result addObject:[self classicApplications]];

		if ([[self networkApplications] isValid])
			[result addObject:[self networkApplications]];
		
		mv_applicationDirectories = [[NSArray alloc] initWithArray:result];
	}	
	
	return mv_applicationDirectories;
}

- (NTFileDesc*)consoleLogs;
{
    return [NTFileDesc descResolve:[self consoleLogsPath]];
}

- (NTFileDesc*)preferencePanes;
{
    return [NTFileDesc descResolve:[self preferencePanesPath]];
}

- (NTFileDesc*)systemPreferencePanes;
{
    return [NTFileDesc descResolve:[self systemPreferencePanesPath]];
}

- (NTFileDesc*)userPreferencePanes
{
    return [NTFileDesc descResolve:[self userPreferencePanesPath]];
}

- (NTFileDesc*)userApplicationSupport;
{
    return [NTFileDesc descResolve:[self userApplicationSupportPath]];
}

- (NTFileDesc*)userApplicationSupportApplication;
{
    return [NTFileDesc descResolve:[self userApplicationSupportApplicationPath]];
}

- (NTFileDesc*)userApplicationSupportPlugins;
{
    return [NTFileDesc descResolve:[self userApplicationSupportPluginsPath]];
}

- (NTFileDesc*)applicationSupport;
{
    return [NTFileDesc descResolve:[self applicationSupportPath]];
}

- (NTFileDesc*)applicationSupportApplication;
{
    return [NTFileDesc descResolve:[self applicationSupportApplicationPath]];
}

- (NTFileDesc*)userApplicationSupportPluginSupport;  // only exists for user, not global
{
	return [NTFileDesc descResolve:[self userApplicationSupportPluginSupportPath]];
}

- (NTFileDesc*)userApplicationSupportSettings;  // only exists for user, not global
{
	return [NTFileDesc descResolve:[self userApplicationSupportSettingsPath]];
}

- (NTFileDesc*)userApplicationSupportCoreData;
{
	return [NTFileDesc descResolve:[self userApplicationSupportCoreDataPath]];
}

- (NTFileDesc*)applicationSupportPlugins;
{
    return [NTFileDesc descResolve:[self applicationSupportPluginsPath]];
}

- (NTFileDesc*)userPreferences;
{
    return [NTFileDesc descResolve:[self userPreferencesPath]];
}

- (NTFileDesc*)userInputManagers;
{
    return [NTFileDesc descResolve:[self userInputManagersPath]];
}

- (NTFileDesc*)inputManagers;
{
    return [NTFileDesc descResolve:[self inputManagersPath]];
}

- (NTFileDesc*)downloads;
{
    return [NTFileDesc descResolve:[self downloadsPath]];
}

- (NTFileDesc*)trashForDesc:(NTFileDesc*)desc create:(BOOL)create;
{
	NTFileDesc *trashDesc = nil;
	
	// made static for speed
	static NTFileDesc *homeDesc=nil;
	if (!homeDesc)
		homeDesc = [[[NTDefaultDirectory sharedInstance] home] retain];
	
	// is this on a different volume than the home folder?
	if ([desc volumeRefNum] != [homeDesc volumeRefNum])
	{
		// network volumes dont have trash cans, but if home is a remote home, then it's OK
		if (![desc isNetwork] && ![desc isVolumeReadOnly])
			trashDesc = [NTFileDesc descResolve:[self trashPathForDesc:desc create:create]];
	}
	else
		trashDesc = [[NTDefaultDirectory sharedInstance] trash];
	
	return trashDesc;
}

@end

@implementation NTDefaultDirectory (Private)

- (NSString *)findSystemFolderType:(int)folderType forDomain:(int)domain createFolder:(BOOL)createFolder;
{
    FSRef fsRef;
    NSString *result = nil;

    OSErr err = FSFindFolder(domain, folderType, createFolder, &fsRef);
    if (!err)
    {
		NTFileDesc* desc = [NTFileDesc descFSRef:&fsRef];
		
		if ([desc isValid])
			result = [desc path];
    }

    return result;
}

@end

