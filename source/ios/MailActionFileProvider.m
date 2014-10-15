//
//  MailActionFileProvider.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/15/14.
//  Copyright (c) 2014 West Virginia University. All rights reserved.
//

#import "MailActionFileProvider.h"
#import "RCFile.h"

@implementation MailActionFileProvider

-(instancetype)initWithRCFile:(RCFile*)file
{
	self = [super initWithPlaceholderItem:[NSURL fileURLWithPath:file.fileContentsPath]];
	self.file = file;
	return self;
}

-(NSString*)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(NSString *)activityType
{
	return [NSString stringWithFormat:@"%@ from Rc²", self.file.name];
}

-(id)item
{
	return [NSURL fileURLWithPath:self.file.fileContentsPath];
}

@end
