//
//  SendMailController.m
//  Rc2Client
//
//  Created by Mark Lilback on 3/14/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "SendMailController.h"

@interface SendMailController () <MFMailComposeViewControllerDelegate>
@property (strong,readwrite) MFMailComposeViewController *composer;
@property (copy) BasicBlock retainSelfBlock;
@end

@implementation SendMailController
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"

-(id)init
{
	self = [super init];
	self.composer = [[MFMailComposeViewController alloc] init];
	self.composer.mailComposeDelegate = self;
	self.retainSelfBlock = ^{ self.retainSelfBlock=nil; };
	return self;
}

#pragma clang diagnostic pop

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	[self.composer.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	if (self.onSuccess)
		self.onSuccess();
	self.retainSelfBlock();
}

@end
