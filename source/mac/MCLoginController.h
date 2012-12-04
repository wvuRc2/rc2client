//
//  MCLoginController.h
//  Rc2Client
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^BasicBlock_t)(void);

@interface MCLoginController : NSWindowController
@property (nonatomic, copy) NSString *loginName;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, assign) NSInteger selectedServerIdx;
@property (nonatomic, assign) BOOL isBusy;

-(void)promptForLoginWithCompletionBlock:(BasicBlock_t)cblock;
- (IBAction)doLogin:(id)sender;
@end
