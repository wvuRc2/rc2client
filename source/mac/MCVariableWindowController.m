//
//  MCVariableWindowController.m
//  Rc2Client
//
//  Created by Mark Lilback on 11/14/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "MCVariableWindowController.h"
#import "MCVariableDisplayController.h"
#import "RCVariable.h"
#import "RCSession.h"
#import "RCWorkspace.h"
#import "RCProject.h"

@implementation MCVariableWindowController
-(id)init
{
	self = [super initWithWindowNibName:@"MCVariableWindowController"];
	return self;
}

-(void)windowDidLoad
{
	//insert initialization code here
}

-(NSString*)saveIdentifier
{
	NSArray *parts = @[self.displayController.session.workspace.project.name, self.displayController.session.workspace.name, self.displayController.variable.name];
	return [parts componentsJoinedByString:@"//"];
}

@end
