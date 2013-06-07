//
//  SessionEditView.h
//  Rc2Client
//
//  Created by Mark Lilback on 5/7/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "SessionEditorProtocol.h"

@interface SessionEditView : UITextView <SessionEditor>
//@property (nonatomic, copy) NSAttributedString *attributedString;
-(IBAction)showHelp:(id)sender;
@end
