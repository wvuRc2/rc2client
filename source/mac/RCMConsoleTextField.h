//
//  RCMConsoleTextField.h
//  MacClient
//
//  Created by Mark Lilback on 12/16/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface RCMConsoleTextField : NSTextField
@property (nonatomic, copy) NSMenu* (^adjustContextualMenuBlock)(NSText *fieldEditor, NSMenu *stdMenu);
-(BOOL)fieldOrEditorIsFirstResponder;
@end
