//
//  MCNewFileController.m
//  MacClient
//
//  Created by Mark Lilback on 12/14/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "MCNewFileController.h"

@implementation MCNewFileController

- (id)init
{
	if ((self = [super initWithWindowNibName:@"MCNewFileController"])) {
	}
	
	return self;
}

- (void)windowDidLoad
{
	[super windowDidLoad];
}

-(IBAction)createFile:(id)sender
{
	NSString *fname = [self.fileName stringByDeletingPathExtension];
	switch (self.fileTypeTag) {
		case 1: //Rnw
			fname = [fname stringByAppendingPathExtension:@"Rnw"];
			break;
		case 2: //txt
			fname = [fname stringByAppendingPathExtension:@"txt"];
			break;
		default:
			fname = [fname stringByAppendingPathExtension:@"R"];
	}
	self.completionHandler(fname);
	[self close];
}

-(IBAction)cancel:(id)sender
{
	self.completionHandler(nil);
}


- (void)controlTextDidChange:(NSNotification *)note
{
	self.canCreate = self.fileNameField.stringValue.length > 0;
}

@synthesize fileName;
@synthesize fileNameField;
@synthesize fileTypePopup;
@synthesize fileTypeTag;
@synthesize canCreate;
@synthesize completionHandler;
@end
