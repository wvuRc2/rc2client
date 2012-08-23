//
//  SessionEditView.h
//  iPadClient
//
//  Created by Mark Lilback on 5/7/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

@interface SessionEditView : UITextView
@property (nonatomic, copy) void (^helpBlock)(SessionEditView *editView);
@property (nonatomic, copy) void (^executeBlock)(SessionEditView *editView);
@property (nonatomic, copy) NSAttributedString *attributedString;
-(IBAction)showHelp:(id)sender;
@end
