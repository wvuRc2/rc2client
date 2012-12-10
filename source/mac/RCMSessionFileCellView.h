//
//  RCMSessionFileCellView.h
//  MacClient
//
//  Created by Mark Lilback on 12/14/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RCMSessionFileCellView : NSTableCellView<NSTextFieldDelegate>
@property (nonatomic, copy) BasicBlock1Arg editCompleteBlock; //argument will be this cell view
@property (nonatomic, weak) IBOutlet NSTextField *nameField;

@end
