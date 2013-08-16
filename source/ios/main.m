//
//  main.m
//  rc2-iPad
//
//  Created by Mark Lilback on 8/5/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>


//fix for 7b5 crazy console logging
typedef int (*PYStdWriter)(void *, const char *, int);
static PYStdWriter _oldStdWrite;


int __pyStderrWrite(void *inFD, const char *buffer, int size)
{
    if ( strncmp(buffer, "AssertMacros:", 13) == 0 ) {
        return 0;
    }
    return _oldStdWrite(inFD, buffer, size);
}

int main(int argc, char *argv[])
{
    _oldStdWrite = stderr->_write;
    stderr->_write = __pyStderrWrite;
	@autoreleasepool {
		int retVal = UIApplicationMain(argc, argv, @"iAMApplication", nil);
		return retVal;
	}
}
