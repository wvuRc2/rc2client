//
//  RCMSessionFileCellView.m
//  MacClient
//
//  Created by Mark Lilback on 12/14/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCMSessionFileCellView.h"
#import "RCFile.h"

@interface RCMSessionFileCellView()
@property (nonatomic, strong) id syncEnabledToken;
@end

@implementation RCMSessionFileCellView

-(IBAction)syncFile:(id)sender
{
	
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	NSImage *img = [NSImage imageNamed:@"syncArrows.png"];
	if (NSBackgroundStyleDark == backgroundStyle)
		img = [NSImage imageNamed:@"syncArrowsSelected.png"];
	if (!self.syncButton.isEnabled)
		img = nil;
	[self.syncButton setImage:img];
	[super setBackgroundStyle:backgroundStyle];
}

-(void)setObjectValue:(id)objectValue
{
	[super setObjectValue:objectValue];
	NSString *name = [objectValue name];
	if (nil == name)
		name = @"";
	self.textField.stringValue = name;
	[self.syncButton setEnabled:[(RCFile*)objectValue locallyModified]];
	if (!self.syncButton.isEnabled)
		self.syncButton.image = nil;
	[self.syncButton.cell setHighlightsBy:NSContentsCellMask];
	self.syncEnabledToken = [objectValue addObserverForKeyPath:@"locallyModified" task:^(RCFile *theFile, NSDictionary *change) {
		[self.syncButton setEnabled:theFile.locallyModified];
		[self setBackgroundStyle:self.backgroundStyle]; //trigger image adjustment
	}];
}

@synthesize syncButton;
@synthesize syncEnabledToken;
@end
