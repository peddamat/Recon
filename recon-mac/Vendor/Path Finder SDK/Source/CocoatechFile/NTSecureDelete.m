//
//  NTSecureDelete.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 6/3/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTSecureDelete.h"
#include <sys/disk.h>
#include <sys/mount.h>
#include <sys/stat.h>
#import <unistd.h>

@interface NTSecureDelete (Private)
- (int)doDeleteFile:(const char *)path;
- (void)setSecurityLevel:(NTDeleteSecurityLevel)securityLevel;
- (NTDeleteSecurityLevel)securityLevel;
- (void)init_random:(const unsigned int)seed;
- (char)random_char;
- (void)randomize_buffer:(unsigned char *)buf length:(int)length;
- (void)flush:(int)fd;
- (void)overwrite;
- (void)overwrite_random:(int)num_passes;
- (void)overwrite_byte:(int)byte;
- (void)overwrite_bytes:(int)byte1 byte2:(int)byte2 byte3:(int)byte3; 
- (void)overwrite_file;
- (int)rename_unlink:(const char *)path;
@end

@implementation NTSecureDelete

- (id)init;
{
	self = [super init];
	
	[self setSecurityLevel:kSimpleSecureDelete];
	mRandFile = -1;
	
	return self;
}

- (void)dealloc;
{
	if (mRandFile != -1)
	{
		close(mRandFile);
		mRandFile = -1;
	}
	
	[super dealloc];
}

+ (NTSecureDelete*)secureDelete:(NTDeleteSecurityLevel)securityLevel;
{
	NTSecureDelete* result = [[NTSecureDelete alloc] init];
	
	[result setSecurityLevel:securityLevel];
	
	return [result autorelease];
}

- (OSStatus)deleteFile:(const char*)path;
{
	int result = [self doDeleteFile:path];

	switch (result)
	{
		case EMLINK:  // too many links, not worried about this
			result = 0;
			break;
	}
	
	return result;
}

@end

@implementation NTSecureDelete (Private)

- (void)init_random:(const unsigned int)seed;
{
	struct stat statbuf;
	
	if (stat("/dev/urandom", &statbuf) == 0 && S_ISCHR(statbuf.st_mode))
		mRandFile = open("/dev/urandom", O_RDONLY);
	else
		srand(seed);
}

- (char)random_char;
{
	char buf[3];
	
	if (mRandFile != -1)
	{
		read(mRandFile, &buf, 1);
		return buf[0];
	}
	
	return rand();
}

- (void)randomize_buffer:(unsigned char *)buf length:(int)length;
{
	int i;
	
	if (mRandFile != -1)
		read(mRandFile, buf, length);
	else 
	{
		for (i = 0; i < length; i++)
			buf[i] = rand();
	}
}

- (void)flush:(int)fd;
{
	fsync(fd);
	
	sync();
	/* if we're root, we can issue an ioctl to flush the device's cache */
	if (getuid() == 0) 
	{
		int err;
		struct statfs sfs;
		if (fstatfs(fd, &sfs) != 0) 
			NSLog(@"\ncannot stat file (%s)\n", strerror(errno));
		else 
		{
			int devfd;
			char rawdevname[MNAMELEN], *ptr;
			strcpy(rawdevname, sfs.f_mntfromname);
			ptr = strrchr(rawdevname, '/');
			
			if (ptr != NULL) 
			{
				memmove(ptr+2, ptr+1, strlen(ptr) + 1);
				ptr[1] = 'r';
			}
			
			devfd = open(rawdevname, O_RDONLY);
			
			if (devfd < 0) 
				NSLog(@"\ncannot open %s : %s\n", rawdevname, strerror(errno));
			else
			{
				err = ioctl(devfd, DKIOCSYNCHRONIZECACHE, NULL);
				if (err) 
					NSLog(@"\nflushing cache on %s returned: %s\n", sfs.f_mntfromname, strerror(errno));

				close(devfd);
			}
		}
	}
}

- (void)overwrite;
{
	u_int32_t i;
	off_t count = 0;
	
	lseek(mFile, 0, SEEK_SET);
	while (count < mFileSize - mBuffSize) 
	{
		i = write(mFile, mBuffer, mBuffSize);
		
		count += i;
	}
	
	i = write(mFile, mBuffer, mFileSize - count);
	[self flush:mFile];
	lseek(mFile, 0, SEEK_SET);
}

- (void)overwrite_random:(int)num_passes;
{
	int i;
	
	for (i = 0; i < num_passes; i++)
	{
		[self randomize_buffer:mBuffer length:mBuffSize];
		[self overwrite];
	}
}

- (void)overwrite_byte:(int)byte;
{
	memset(mBuffer, byte, mBuffSize);
	[self overwrite];
}

- (void)overwrite_bytes:(int)byte1 byte2:(int)byte2 byte3:(int)byte3; 
{
	int i;
	
	memset(mBuffer, byte1, mBuffSize);
	for (i = 1; i < mBuffSize; i += 3) 
	{
		mBuffer[i] = byte2;
		mBuffer[i+1] = byte3;
	}
	[self overwrite];
}

- (void)overwrite_file;
{		
	switch ([self securityLevel])
	{
		case kNormalDelete: // keep the compiler from warning
		case kSimpleSecureDelete:
		{
			/* simple one-pass overwrite */
			[self overwrite_random:1];
		}
			break;
		case kMediumSecureDelete:
		{
			/* DoD-compliant 7-pass overwrite */
			[self overwrite_byte:0xF6];
			[self overwrite_byte:0x00];
			[self overwrite_byte:0xFF];
			[self overwrite_random:1];
			[self overwrite_byte:0x00];
			[self overwrite_byte:0xFF];
			[self overwrite_random:1];			
		}
			break;
		case kUltraSecureDelete:
		{
			/* Gutmann 35-pass overwrite */
			[self overwrite_random:4];
			[self overwrite_byte:0x55];
			[self overwrite_byte:0xAA];
			[self overwrite_bytes:0x92 byte2:0x49 byte3:0x24];
			[self overwrite_bytes:0x49 byte2:0x24 byte3:0x92];
			[self overwrite_bytes:0x24 byte2:0x92 byte3:0x49];
			[self overwrite_byte:0x00];
			[self overwrite_byte:0x11];
			[self overwrite_byte:0x22];
			[self overwrite_byte:0x33];
			[self overwrite_byte:0x44];
			[self overwrite_byte:0x55];
			[self overwrite_byte:0x66];
			[self overwrite_byte:0x77];
			[self overwrite_byte:0x88];
			[self overwrite_byte:0x99];
			[self overwrite_byte:0xAA];
			[self overwrite_byte:0xBB];
			[self overwrite_byte:0xCC];
			[self overwrite_byte:0xDD];
			[self overwrite_byte:0xEE];
			[self overwrite_byte:0xFF];
			[self overwrite_bytes:0x92 byte2:0x49 byte3:0x24];
			[self overwrite_bytes:0x49 byte2:0x24 byte3:0x92];
			[self overwrite_bytes:0x24 byte2:0x92 byte3:0x49];
			[self overwrite_bytes:0x6D byte2:0xB6 byte3:0xDB];
			[self overwrite_bytes:0xB6 byte2:0xDB byte3:0x6D];
			[self overwrite_bytes:0xDB byte2:0x6D byte3:0xB6];
			[self overwrite_random:4];			
		}
			break;
	}
	
	// zero out blocks
	[self overwrite_byte:0x00];
}

- (int)doDeleteFile:(const char *)path;
{
	struct stat statbuf;
	struct statfs fs_stats;
	struct flock flock;
	
	if (lstat(path, &statbuf) == -1) 
		return -1;
	if (!S_ISREG(statbuf.st_mode))
		return [self rename_unlink:path];
	
	if (statbuf.st_nlink > 1) 
	{
		[self rename_unlink:path];
		return EMLINK;
	}
	
	mFileSize = statbuf.st_size;
	mBuffSize = statbuf.st_blksize;
	
	if ((mBuffer = (unsigned char *)alloca(mBuffSize)) == NULL ) 
	{
		return ENOMEM;
	}
	
	if ( (mFile = open(path, O_WRONLY)) == -1) /* BSD doesn't support O_SYNC */
		return -1;
	
	if (fcntl(mFile, F_WRLCK, &flock) == -1)
	{
		close(mFile);
		return -1;
	}
	
	if (fstatfs(mFile, &fs_stats) == -1 && errno != ENOSYS)
	{
		close(mFile);
		return -1;
	}
	
	/* warn when trying to overwrite files on a non-local fs,
		since there are no guarantees that writes will not be
		buffered on the server, or will overwrite the same spot. */
	if ((fs_stats.f_flags & MNT_LOCAL) == 0) 
	{
		printf("warning: %s is not on a local filesystem!\n", path);
		fflush(stdout);
	}
	
	[self overwrite_file];
	
	if (ftruncate(mFile, 0) == -1) 
	{
		close(mFile);
		return -1;
	}
	
	close(mFile);
	
	/* Also overwrite the file's resource fork, if present. */
	{
		static const char *RSRCFORKSPEC = "/..namedfork/rsrc";
		size_t rsrc_fork_size;
		size_t rsrc_path_size = strlen(path) + strlen(RSRCFORKSPEC) + 1;
		char *rsrc_path = (char *)alloca(rsrc_path_size);
		
		if (rsrc_path == NULL)
			return ENOMEM;
		
		if (snprintf(rsrc_path, MAXPATHLEN, "%s%s", path, RSRCFORKSPEC ) > MAXPATHLEN - 1) 
			return ENAMETOOLONG;
		
		if (lstat(rsrc_path, &statbuf) != 0) 
		{
			int err = errno;
			if (err == ENOENT || err == ENOTDIR)
				rsrc_fork_size = 0;
			else
				return -1;
		}
		else 
			rsrc_fork_size = statbuf.st_size;
		
		if (rsrc_fork_size > 0)
		{
			mFileSize = rsrc_fork_size;
			
			if ((mFile = open(rsrc_path, O_WRONLY)) == -1) 
				return -1;
			if (fcntl(mFile, F_WRLCK, &flock) == -1)
			{
				close(mFile);
				return -1;
			}
			
			[self overwrite_file];
			
			if (ftruncate(mFile, 0) == -1)
			{
				close(mFile);
				return -1;
			}
			
			close(mFile);
		}
	}
	
	return [self rename_unlink:path];
}

- (void)setSecurityLevel:(NTDeleteSecurityLevel)securityLevel;
{
	mSecurityLevel = securityLevel;
}

- (NTDeleteSecurityLevel)securityLevel;
{
	return mSecurityLevel;
}

- (int)rename_unlink:(const char *)path;
{
	char *new_name, *p, c;
	struct stat statbuf;
	size_t new_name_size = strlen(path) + 15;
	int i = 0;
	
	if ( (new_name = (char *)alloca(new_name_size)) == NULL ) 
		return ENOMEM;
	
	strncpy(new_name, path, new_name_size);
	
	if ( (p = strrchr(new_name, '/')) != NULL ) 
	{
		p++;
		*p = '\0';
	}
	else
		p = new_name;
	
	do 
	{
		i = 0;
		
		while (i < 14)
		{
			c = [self random_char];
			if (isalnum((int) c))
			{
				p[i] = c;
				i++;
			}
		}
		p[i] = '\0';
	} while (lstat(new_name, &statbuf) == 0);
	
	if (lstat(path, &statbuf) == -1)
		return -1;
	
	if (S_ISDIR(statbuf.st_mode) && (statbuf.st_nlink > 2)) 
	{
		/* Directory isn't empty (e.g. because it contains an immutable file).
		Attempting to remove it will fail, so avoid renaming it. */
		return ENOTEMPTY;
	}
	
	if (rename(path, new_name) == -1)
		return -1;
	
	sync();
	
	if (lstat(new_name, &statbuf) == -1)
	{
		/* Bad mojo, we just renamed to new_name and now the path is invalid.
		Die ungracefully and exit before anything worse happens. */
		perror("Fatal error in rename_unlink()");
		exit(EXIT_FAILURE);
	}
	
	if (S_ISDIR(statbuf.st_mode))
		return rmdir(new_name);
	
	return unlink(new_name);
}

@end
