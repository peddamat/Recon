/*
 *  NTPluginConstants.h
 *
 *  Created by Steve Gehrman on 5/5/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */
typedef enum NTFileAttributeID
{
	// ## Finder flags
	kAlias_attributeID=1,           // kIsAlias
	kHasBundle_attributeID,         // kHasBundle
	kCustomIcon_attributeID,        // kHasCustomIcon
	kOnDesktop_attributeID,         // kIsOnDesk
	kInited_attributeID,            // kHasBeenInited
	kNameLocked_attributeID,        // kNameLocked
	kStationeryPad_attributeID,     // kIsStationery
	kInvisible_attributeID,         // kIsInvisible
	
	kLabel_attributeID,
	kLength_attributeID,            // truncates file
	kLocked_attributeID,
	kExtensionHidden_attributeID,
	
	kType_attributeID,
	kCreator_attributeID,
	kAttributeModificationDate_attributeID,
	kModificationDate_attributeID,
	kCreationDate_attributeID,
	
	kOwner_attributeID,
	kGroup_attributeID,
	kPermissions_attributeID,
	kStickyBit_attributeID,
	kSpotlightComments_attributeID,
	
} NTFileAttributeID;

typedef enum NTStateValue
{
    NTMixedState = -1,  // toggle
    NTOffState   =  0,
    NTOnState    =  1    
} NTStateValue;

