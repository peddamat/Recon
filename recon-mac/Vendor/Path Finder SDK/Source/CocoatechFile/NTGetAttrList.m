//
//  NTGetAttrList.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Sun Dec 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NTGetAttrList.h"
#include <assert.h>
#include <stdio.h>
#include <stddef.h>
#include <string.h>
#include <sys/attr.h>
#include <sys/errno.h>
#include <unistd.h>
#include <sys/vnode.h>

@implementation NTGetAttrList

struct MYVolAttrBuf
{
    unsigned long   length;
    vol_capabilities_attr_t volCapabilities;
};

+ (BOOL)volumeSupportsSearchFS:(const char*)UTFPath;
{
    int             err;
    struct attrlist attrList;
    struct MYVolAttrBuf    attrBuf;
        
    memset(&attrList, 0, sizeof(attrList));
    attrList.bitmapcount = ATTR_BIT_MAP_COUNT;
    attrList.volattr = (ATTR_VOL_INFO | ATTR_VOL_CAPABILITIES);  // ATTR_VOL_INFO must be set, otherwise it just doesn't work - Unix sucks balls (see man page)
        
    err = getattrlist(UTFPath, &attrList, &attrBuf, sizeof(attrBuf), 0);
    if (err != 0)
        err = errno;
    
    if (err == 0) 
    {
        assert(attrBuf.length == sizeof(attrBuf));

        if ((attrBuf.volCapabilities.valid[VOL_CAPABILITIES_INTERFACES] & VOL_CAP_INT_SEARCHFS) == VOL_CAP_INT_SEARCHFS)
        {
            if ((attrBuf.volCapabilities.capabilities[VOL_CAPABILITIES_INTERFACES] & VOL_CAP_INT_SEARCHFS) == VOL_CAP_INT_SEARCHFS)
                return YES;
        }
    }
    
    return err;
}

// used for testing...

typedef struct FInfoAttrBuf
{
    unsigned long   length;
    fsobj_type_t    objType;
    fsobj_type_t    objID;
    fsobj_type_t    objPID;
    char            finderInfo[32];
} FInfoAttrBuf;

+ (void)test:(const char *)path;
{
    int             err;
    struct attrlist      attrList;
    FInfoAttrBuf    attrBuf;
    
    memset(&attrList, 0, sizeof(attrList));
    attrList.bitmapcount = ATTR_BIT_MAP_COUNT;
    attrList.commonattr  = ATTR_CMN_OBJTYPE | ATTR_CMN_OBJID | ATTR_CMN_OBJPERMANENTID | ATTR_CMN_FNDRINFO;
    
    err = getattrlist(path, &attrList, &attrBuf, sizeof(attrBuf), 0);
    if (err != 0)
        err = errno;
    
    if (err == 0) 
    {
        assert(attrBuf.length == sizeof(attrBuf));
        
        printf("Finder information for %s:\n", path);
        switch (attrBuf.objType) 
        {
            case VREG:
                printf("file type    = '%.4s'\n", &attrBuf.finderInfo[0]);
                printf("file creator = '%.4s'\n", &attrBuf.finderInfo[4]);
                break;
            case VDIR:
                printf("directory\n");
                break;
            default:
                printf("other object type, %d\n", attrBuf.objType);
                break;
        }
        
        printf("other object id,permID, %d, %d\n", attrBuf.objID, attrBuf.objPID);

    }
}

@end

#if 0 

// example code from man page

// The following code prints the file type and creator of a file, assuming
// that the volume supports the required attributes.


typedef struct FInfoAttrBuf
{
    unsigned long   length;
    fsobj_type_t    objType;
    char            finderInfo[32];
} FInfoAttrBuf;

static int FInfoDemo(const char *path)
{
    int             err;
    attrlist_t      attrList;
    FInfoAttrBuf    attrBuf;
    
    memset(&attrList, 0, sizeof(attrList));
    attrList.bitmapcount = ATTR_BIT_MAP_COUNT;
    attrList.commonattr  = ATTR_CMN_OBJTYPE | ATTR_CMN_FNDRINFO;
    
    err = getattrlist(path, &attrList, &attrBuf, sizeof(attrBuf), 0);
    if (err != 0)
        err = errno;
    
    if (err == 0) 
    {
        assert(attrBuf.length == sizeof(attrBuf));
        
        printf("Finder information for %s:\n", path);
        switch (attrBuf.objType) 
        {
            case VREG:
                printf("file type    = '%.4s'\n", &attrBuf.finderInfo[0]);
                printf("file creator = '%.4s'\n", &attrBuf.finderInfo[4]);
                break;
            case VDIR:
                printf("directory\n");
                break;
            default:
                printf("other object type, %d\n", attrBuf.objType);
                break;
        }
    }
    
    return err;
}

// ==========================================================================================================================

// The following code is an alternative implementation that uses nested
// structures to group the related attributes.

typedef struct attrlist attrlist_t;

struct FInfo2CommonAttrBuf {
    fsobj_type_t    objType;
    char            finderInfo[32];
};
typedef struct FInfo2CommonAttrBuf FInfo2CommonAttrBuf;

struct FInfo2AttrBuf {
    unsigned long       length;
    FInfo2CommonAttrBuf common;
};
typedef struct FInfo2AttrBuf FInfo2AttrBuf;

static int FInfo2Demo(const char *path)
{
    int             err;
    attrlist_t      attrList;
    FInfo2AttrBuf   attrBuf;
    
    memset(&attrList, 0, sizeof(attrList));
    attrList.bitmapcount = ATTR_BIT_MAP_COUNT;
    attrList.commonattr  = ATTR_CMN_OBJTYPE | ATTR_CMN_FNDRINFO;
    
    err = getattrlist(path, &attrList, &attrBuf, sizeof(attrBuf), 0);
    if (err != 0) {
        err = errno;
    }
    
    if (err == 0) {
        assert(attrBuf.length == sizeof(attrBuf));
        
        printf("Finder information for %s:\n", path);
        switch (attrBuf.common.objType) {
            case VREG:
                printf(
                       "file type    = '%.4s'\n",
                       &attrBuf.common.finderInfo[0]
                       );
                printf(
                       "file creator = '%.4s'\n",
                       &attrBuf.common.finderInfo[4]
                       );
                break;
            case VDIR:
                printf("directory\n");
                break;
            default:
                printf(
                       "other object type, %d\n",
                       attrBuf.common.objType
                       );
                break;
        }
    }
    
    return err;
}

// ==========================================================================================================================
// The following example shows how to deal with variable length attributes.
// It assumes that the volume specified by path supports the necessary
// attributes.

typedef struct attrlist attrlist_t;

struct VolAttrBuf {
    unsigned long   length;
    unsigned long   fileCount;
    unsigned long   dirCount;
    attrreference_t mountPointRef;
    attrreference_t volNameRef;
    char            mountPointSpace[MAXPATHLEN];
    char            volNameSpace[MAXPATHLEN];
};
typedef struct VolAttrBuf VolAttrBuf;

static int VolDemo(const char *path)
{
    int             err;
    attrlist_t      attrList;
    VolAttrBuf      attrBuf;
    
    memset(&attrList, 0, sizeof(attrList));
    attrList.bitmapcount = ATTR_BIT_MAP_COUNT;
    attrList.volattr     =   ATTR_VOL_INFO
        | ATTR_VOL_FILECOUNT
        | ATTR_VOL_DIRCOUNT
        | ATTR_VOL_MOUNTPOINT
        | ATTR_VOL_NAME;
    
    err = getattrlist(path, &attrList, &attrBuf, sizeof(attrBuf), 0);
    if (err != 0) {
        err = errno;
    }
    
    if (err == 0) {
        assert(attrBuf.length >  offsetof(VolAttrBuf, mountPointSpace));
        assert(attrBuf.length <= sizeof(attrBuf));
        
        printf("Volume information for %s:\n", path);
        printf("ATTR_VOL_FILECOUNT:  %lu\n", attrBuf.fileCount);
        printf("ATTR_VOL_DIRCOUNT:   %lu\n", attrBuf.dirCount);
        printf(
               "ATTR_VOL_MOUNTPOINT: %.*s\n",
               (int) attrBuf.mountPointRef.attr_length,
               ( ((char *) &attrBuf.mountPointRef)
                 + attrBuf.mountPointRef.attr_dataoffset )
               );
        printf(
               "ATTR_VOL_NAME:       %.*s\n",
               (int) attrBuf.volNameRef.attr_length,
               ( ((char *) &attrBuf.volNameRef)
                 + attrBuf.volNameRef.attr_dataoffset )
               );
    }
    
    return err;
}

#endif
