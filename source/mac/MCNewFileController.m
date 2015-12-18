//
//  MCNewFileController.m
//  MacClient
//
//  Created by Mark Lilback on 12/14/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "Rc2-Swift.h"
#import "MCNewFileController.h"

@interface MCNewFileController()
@property (nonatomic, strong) IBOutlet NSTextField *fileNameField;
@property (nonatomic, strong) IBOutlet NSPopUpButton *fileTypePopup;
@property (nonatomic, strong) IBOutlet Rc2FileType *selectedFileType;
@property (nonatomic, copy) IBOutlet NSArray *availableFileTypes;
@end

@implementation MCNewFileController

- (id)init
{
	if ((self = [super initWithWindowNibName:@"MCNewFileController"])) {
		self.availableFileTypes = [Rc2FileType creatableFileTypes];
		self.selectedFileType = [Rc2FileType fileTypeWithExtension:@"R"];
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
	fname = [fname stringByAppendingPathExtension:self.selectedFileType.fileExtension];
	self.completionHandler(fname);
	[self close];
}

-(IBAction)cancel:(id)sender
{
	self.completionHandler(nil);
	[self close];
}


- (void)controlTextDidChange:(NSNotification *)note
{
	self.canCreate = self.fileNameField.stringValue.length > 0;
}

@end
