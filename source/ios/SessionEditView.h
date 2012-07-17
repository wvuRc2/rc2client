//
//  SessionEditView.h
//  iPadClient
//
//  Created by Mark Lilback on 5/7/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import "DTRichTextEditor.h"

@interface SessionEditView : DTRichTextEditorView
@property (nonatomic, copy) void (^helpBlock)(SessionEditView *editView);
-(IBAction)showHelp:(id)sender;
@end
