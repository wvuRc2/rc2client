//
//  DrropboxUploadActivity.m
//  Rc2Client
//
//  Created by Mark Lilback on 11/20/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "DrropboxUploadActivity.h"
#import "RCFile.h"
#import "DropboxFolderSelectController.h"

@interface DrropboxUploadActivity ()
@end

@implementation DrropboxUploadActivity

-(UIImage*)activityImage
{
	return [UIImage imageNamed:@"dropboxActivityIcon"];
}

-(NSString*)activityTitle { return @"Dropbox"; }

-(NSString*)activityType { return @"edu.wvu.stat.rc2.activty.dropbox"; }

-(BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
	if (self.filesToUpload.count < 1)
		return NO;
	for (id aFile in self.filesToUpload) {
		if (![aFile isKindOfClass:[RCFile class]])
			return NO;
	}
	return YES;
}

-(void)performActivity
{
	[self activityDidFinish:YES];
	dispatch_async(dispatch_get_main_queue(), ^{
		self.performBlock();
	});
}

@end
