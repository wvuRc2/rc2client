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



@end
