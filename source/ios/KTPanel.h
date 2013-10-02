//
//  KTPanel.h
//  Rc2Client
//
//  Created by Mark Lilback on 9/30/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class kTController;

@interface KTPanel : NSObject
@property (nonatomic, strong) IBOutlet UIView *view;
@property (nonatomic, strong) NSLayoutConstraint *xConstraint;

-(id)initWithNibName:(NSString*)nibName controller:(kTController*)controller;
-(void)panelWillAppear;
@end
