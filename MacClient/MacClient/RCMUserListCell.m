//
//  RCMUserListCell.m
//  MacClient
//
//  Created by Mark Lilback on 2/10/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import "RCMUserListCell.h"
#import "RCSessionUser.h"

@implementation RCMUserListCell

-(void)setObjectValue:(id)objectValue
{
	[super setObjectValue:objectValue];
	if ([[objectValue valueForKey:@"control"] boolValue])
		self.imgButton.image = [NSImage imageNamed:NSImageNameStatusAvailable];
	else if ([[objectValue valueForKey:@"master"] boolValue])
		self.imgButton.image = [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
	else
		self.imgButton.image = [NSImage imageNamed:NSImageNameStatusNone];
	[self.imgButton.cell setBackgroundColor:[NSColor clearColor]];
	if ([[objectValue valueForKey:@"handRaised"] boolValue])
		self.handButton.state = NSOnState;
	else 
		self.handButton.state = NSOffState;
}

@synthesize imgButton;
@synthesize handButton;
@end
