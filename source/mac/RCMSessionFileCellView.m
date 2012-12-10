//
//  RCMSessionFileCellView.m
//  MacClient
//
//  Created by Mark Lilback on 12/14/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCMSessionFileCellView.h"
#import "RCFile.h"

@interface RCMSessionFileCellView()
@property (nonatomic, strong) id syncEnabledToken;
@end

@implementation RCMSessionFileCellView

-(void)controlTextDidEndEditing:(NSNotification *)obj
{
	[self.nameField setEditable:NO];
	if (self.editCompleteBlock)
		self.editCompleteBlock(self);
	self.nameField.stringValue = [self.objectValue name];
}

-(void)setObjectValue:(id)objectValue
{
	[super setObjectValue:objectValue];
	NSString *name = [objectValue name];
	if (nil == name)
		name = @"";
	self.nameField.stringValue = name;
}

@end
