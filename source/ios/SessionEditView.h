//
//  SessionEditView.h
//  Rc2Client
//
//  Created by Mark Lilback on 5/7/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

@interface SessionEditView : UITextView
@property (nonatomic, copy) void (^helpBlock)(SessionEditView *editView);
@property (nonatomic, copy) void (^executeBlock)(SessionEditView *editView);
@property (nonatomic, copy) NSAttributedString *attributedString;
-(IBAction)showHelp:(id)sender;
@end
