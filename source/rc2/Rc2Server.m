//
//  Rc2Server.m
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "Rc2-Swift.h"
#import "Rc2Server.h"
#import "RC2ServerAFNet1.h"

NSString * const RC2NotificationsReceivedNotification = @"RC2NotificationsReceivedNotification";
NSString * const RC2MessagesUpdatedNotification = @"RC2MessagesUpdatedNotification";
NSString * const RC2FileDeletedNotification = @"RC2FileDeletedNotification";

static __strong id<Rc2Server> gServer;

id<Rc2Server> RC2_SharedInstance()
{
	static dispatch_once_t pred;
	
	dispatch_once(&pred, ^{
		if (nil == gServer)
			gServer = [[RC2ServerAFNet1 alloc] init];
	});
	
	return gServer;
}

//this exists soley to be used by unit tests that need to mock the server
void RC2_SetSharedInstance(id<Rc2Server> server)
{
	if (gServer) {
		NSLog(@"%s called when value already exists", __PRETTY_FUNCTION__);
	}
	gServer = server;
}

NSArray* RC2_AcceptableTextFileSuffixes()
{
	return [Rc2FileType textFileTypes];
}

NSArray* RC2_AcceptableImportFileSuffixes()
{
	return [Rc2FileType importableFileTypes];
}

