//
//  RCMConsoleTextField.m
//  MacClient
//
//  Created by Mark Lilback on 12/16/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCMConsoleTextField.h"

@implementation RCMConsoleTextField

-(BOOL)fieldOrEditorIsFirstResponder
{
	return nil != self.currentEditor;
}

-(void)updateContextMenu
{
	if (self.adjustContextualMenuBlock) {
		NSMenu *menu = self.currentEditor.menu;
		menu = self.adjustContextualMenuBlock(self.currentEditor, menu);
		self.currentEditor.menu = menu;
	}
}

-(void)textDidBeginEditing:(NSNotification *)notification
{
	[super textDidBeginEditing:notification];
	[self updateContextMenu];
}

-(void)textDidEndEditing:(NSNotification *)notification
{
	self.currentEditor.menu = [NSTextView defaultMenu];
}

-(void)textViewDidChangeSelection:(NSNotification*)note
{
	[self updateContextMenu];
}
@end
