//
//  RCMSessionFileCellView.h
//  MacClient
//
//  Created by Mark Lilback on 12/14/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RCMSessionFileCellView : NSTableCellView
@property (nonatomic, strong) IBOutlet NSButton *syncButton;

-(IBAction)syncFile:(id)sender;
@end
