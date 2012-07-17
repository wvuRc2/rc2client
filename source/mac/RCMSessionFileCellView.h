//
//  RCMSessionFileCellView.h
//  MacClient
//
//  Created by Mark Lilback on 12/14/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RCMSessionFileCellView : NSTableCellView
@property (nonatomic, strong) IBOutlet NSButton *syncButton;
@property (nonatomic, copy) BasicBlock1Arg syncFileBlock; //argument will be the RCFile object

-(IBAction)syncFile:(id)sender;
@end
