//
//  NTPathFinderRemoteUtilities.h
//  Path Finder Remote
//
//  Created by Steve Gehrman on 4/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

// localized string "Reveal in Path Finder"
CFStringRef revealInPathFinderLocalizedString();

void launchPathFinder();
Boolean isPathFinderRunning();
void activatePathFinder();
Boolean pathFinderIsCurrentApplication();

	// third party apps can use this to determine if they should pass reveal appleevents to Path Finder
	// the preferece is set in Path Finders preference panel
Boolean revealInPathFinderPreferenceEnabled();
void setRevealInPathFinderPreferenceEnabled(Boolean set);

	// sends a reveal event the old fashion way
void revealInPathFinderUsingAppleEvent(FSRef *ref);

