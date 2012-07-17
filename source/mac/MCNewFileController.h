//
//  MCNewFileController.h
//  MacClient
//
//  Created by Mark Lilback on 12/14/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MCNewFileController : NSWindowController<NSTextFieldDelegate>
@property (nonatomic, strong) IBOutlet NSTextField *fileNameField;
@property (nonatomic, strong) IBOutlet NSPopUpButton *fileTypePopup;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic) NSInteger fileTypeTag;
@property (nonatomic) BOOL canCreate;
//the argument will be the file name, or nil if user canceled
@property (copy) BasicBlock1Arg completionHandler;

-(IBAction)createFile:(id)sender;
-(IBAction)cancel:(id)sender;
@end
