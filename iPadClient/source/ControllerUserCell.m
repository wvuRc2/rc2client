//
//  ControllerUserCell.m
//  iPadClient
//
//  Created by Mark Lilback on 2/17/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import "ControllerUserCell.h"
#import "RCSessionUser.h"

@implementation ControllerUserCell
@synthesize user=_user;
@synthesize nameLabel;
@synthesize handButton;

-(void)setUser:(RCSessionUser *)user
{
	_user = user;
	if (user) {
		self.nameLabel.text = user.login;
		self.handButton.selected = user.handRaised;
	}
}
@end
