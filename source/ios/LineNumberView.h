//
//  LineNumberView.h
//  Rc2Client
//
//  Created by Mark Lilback on 6/18/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DTRichTextEditorView;

@interface LineNumberView : UIView
@property (nonatomic, weak) DTRichTextEditorView *editor;
-(void)editorContentChanged;
@end
