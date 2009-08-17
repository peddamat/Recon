//
//  NTDefaultDirectory.h
//  CocoatechFile
//
//  Created by sgehrman on Tue Jun 05 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFileDesc;

@interface NTDefaultDirectory : NTSingletonObject
{
    NSString* _homePath;
    NSString* _favoritesPath;
    NSString* _trashPath;
    NSString* _userLibraryPath;
    NSString* _userContextualMenuItemsPath;
    NSString* _userApplicationsPath;
    NSString* _desktopPath;
    NSString* _documentsPath;
    NSString* _musicPath;
    NSString* _moviesPath;
    NSString* _picturesPath;
    NSString* _sitesPath;
    NSString* _publicPath;

    NSString* _userApplicationSupportPath;
    NSString* _userApplicationSupportApplicationPath;
    NSString* _userApplicationSupportPluginsPath;
    NSString* _userApplicationSupportSettingsPath;
    NSString* _userApplicationSupportCoreDataPath;

    NSString* _applicationSupportPath;
    NSString* _applicationSupportApplicationPath;
    NSString* _applicationSupportPluginsPath;
    NSString* _userApplicationSupportPluginSupportPath;
	
    NSString* _userPreferencesPath;
    
    NSString* _computerPath;
    NSString* _rootPath;
    NSString* _systemPath;
    NSString* _usersPath;
    NSString* _libraryPath;
    NSString* _applicationsPath;
    NSString* mUtilitiesPath;
	NSString* mDownloadsPath;
    NSString* _classicApplicationsPath;
    NSString* _developerApplicationsPath;
    NSString* _networkApplicationsPath;
    NSString* _tmpPath;
    NSString* _contextualMenuItemsPath;
    NSString* _recentServersPath;
    NSString* savedSearchesPath;
    
    NSString* _userPreferencePanesPath;
    NSString* _preferencePanesPath;
    NSString* _systemPreferencePanesPath;
    
    NSString* _userInputManagersPath;
    NSString* _inputManagersPath;
	
	NSString* _logsPath;
	NSString* _userLogsPath;
	NSString* _varlogPath;
	NSString* _consoleLogsPath;	
	NSString* _desktopPicturesPath;
	
	NSArray* mv_applicationDirectories;
}

@property (retain) NSString* savedSearchesPath;

+ (NTDefaultDirectory*)sharedInstance;

    // home directories
- (NSString*)homePath;
- (NSString*)favoritesPath;
- (NSString*)userLibraryPath;
- (NSString*)userContextualMenuItemsPath;
- (NSString*)userApplicationsPath;
- (NSString*)desktopPath;
- (NSString*)documentsPath;
- (NSString*)musicPath;
- (NSString*)moviesPath;
- (NSString*)picturesPath;
- (NSString*)sitesPath;
- (NSString*)publicPath;
- (NSString*)recentServersPath;
- (NSString*)userLogsPath;

- (NSString*)userApplicationSupportPath;
- (NSString*)userApplicationSupportApplicationPath;
- (NSString*)userApplicationSupportPluginsPath;
- (NSString*)userApplicationSupportCoreDataPath;
- (NSString*)userApplicationSupportPluginSupportPath;  // only exists for user, not global
- (NSString*)userApplicationSupportSettingsPath;  // only exists for user, not global

- (NSString*)applicationSupportPath;
- (NSString*)applicationSupportApplicationPath;
- (NSString*)applicationSupportPluginsPath;

- (NSString*)userPreferencesPath;

- (NSString*)desktopPicturesPath;

- (NSString*)preferencePanesPath;
- (NSString*)userPreferencePanesPath;    
- (NSString*)systemPreferencePanesPath;

- (NSString*)userInputManagersPath;
- (NSString*)inputManagersPath;

    // system directories
- (NSString*)computerPath;
- (NSString*)rootPath;
- (NSString*)systemPath;
- (NSString*)usersPath;
- (NSString*)libraryPath;
- (NSString*)applicationsPath;
- (NSString *)utilitiesPath;

- (NSString*)classicApplicationsPath;
- (NSString*)networkApplicationsPath;
- (NSString*)developerApplicationsPath;
- (NSString*)tmpPath;
- (NSString*)contextualMenuItemsPath;
- (NSString*)logsPath;
- (NSString*)consoleLogsPath;
- (NSString*)varlogPath;

- (NSString*)downloadsPath;

- (NSString*)trashPath;
- (NSString*)trashPathForDesc:(NTFileDesc*)desc create:(BOOL)create;

    // ============================================
    // similar routines, but they return a NTFileDesc

    // home directories
- (NTFileDesc*)home;
- (NTFileDesc*)favorites;
- (NTFileDesc*)userLibrary;
- (NTFileDesc*)userContextualMenuItems;
- (NTFileDesc*)userApplications;
- (NTFileDesc*)desktop;
- (NTFileDesc*)documents;
- (NTFileDesc*)music;
- (NTFileDesc*)movies;
- (NTFileDesc*)pictures;
- (NTFileDesc*)sites;
- (NTFileDesc*)public;
- (NTFileDesc*)recentServers;

- (NTFileDesc*)userApplicationSupport;
- (NTFileDesc*)userApplicationSupportApplication;
- (NTFileDesc*)userApplicationSupportPlugins;
- (NTFileDesc*)userApplicationSupportPluginSupport;  // only exists for user, not global
- (NTFileDesc*)userApplicationSupportSettings;  // only exists for user, not global
- (NTFileDesc*)userApplicationSupportCoreData; 
- (NTFileDesc *)savedSearches;

- (NTFileDesc*)applicationSupport;
- (NTFileDesc*)applicationSupportApplication;
- (NTFileDesc*)applicationSupportPlugins;

- (NTFileDesc*)userPreferences;

- (NTFileDesc*)preferencePanes;
- (NTFileDesc*)userPreferencePanes;
- (NTFileDesc*)systemPreferencePanes;

- (NTFileDesc*)desktopPictures;

- (NTFileDesc*)userInputManagers;
- (NTFileDesc*)inputManagers;

    // system directories
- (NTFileDesc*)computer;
- (NTFileDesc*)root;
- (NTFileDesc*)system;
- (NTFileDesc*)users;
- (NTFileDesc*)library;
- (NTFileDesc*)applications;
- (NTFileDesc*)utilities;
- (NTFileDesc*)classicApplications;
- (NTFileDesc*)developerApplications;
- (NTFileDesc*)networkApplications;
- (NTFileDesc*)tmp;
- (NTFileDesc*)contextualMenuItems;
- (NTFileDesc*)logs;
- (NTFileDesc*)consoleLogs;
- (NTFileDesc*)varlog;
- (NTFileDesc*)userLogs;

- (NTFileDesc*)downloads;

- (NTFileDesc*)trash;
- (NTFileDesc*)trashForDesc:(NTFileDesc*)desc create:(BOOL)create;

- (NSArray*)applicationDirectories;
@end
