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

-(IBAction)syncFile:(id)sender
{
	RCFile *file = (RCFile*)self.objectValue;
	if (!file.readOnlyValue)
		self.syncFileBlock(self.objectValue);
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	RCFile *file = (RCFile*)self.objectValue;
	if (file.readOnlyValue || file.kind != nil) {
		self.syncButton.image = file.permissionImage;
	} else {
		NSImage *img = [NSImage imageNamed:@"syncArrows.png"];
		if (NSBackgroundStyleDark == backgroundStyle)
			img = [NSImage imageNamed:@"syncArrowsSelected.png"];
		if (!self.syncButton.isEnabled)
			img = nil;
		[self.syncButton setImage:img];
	}
	[super setBackgroundStyle:backgroundStyle];
}

-(void)setObjectValue:(id)objectValue
{
	[super setObjectValue:objectValue];
	RCFile *file = (RCFile*)objectValue;
	NSString *name = [objectValue name];
	if (nil == name)
		name = @"";
	self.textField.stringValue = name;
	if (file.readOnlyValue || file.kind != nil) {
		self.syncButton.image = file.permissionImage;
		[self.syncButton setEnabled:NO];
	} else {
		[self.syncButton setEnabled:file.locallyModified];
		if (!self.syncButton.isEnabled)
			self.syncButton.image = nil;
	}
	[self.syncButton.cell setHighlightsBy:NSContentsCellMask];
	self.syncEnabledToken = [objectValue addObserverForKeyPath:@"locallyModified" task:^(RCFile *theFile, NSDictionary *change) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.syncButton setEnabled:theFile.locallyModified && !theFile.readOnlyValue];
			[self setBackgroundStyle:self.backgroundStyle]; //trigger image adjustment
		});
	}];
}

@synthesize syncButton;
@synthesize syncEnabledToken;
@synthesize syncFileBlock;
@end
