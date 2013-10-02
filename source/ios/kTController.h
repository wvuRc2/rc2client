//
//  kTController.h
//  Rc2Client
//
//  Created by Mark Lilback on 9/30/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KTControllerDelegate;

@interface kTController : NSObject
@property (nonatomic, copy, readonly) NSArray *panels;
@property (nonatomic, strong, readonly) UIView *view;
@property (nonatomic, strong) UIInputView *inputView;
@property (nonatomic, weak) id<KTControllerDelegate> delegate;

-(id)initWithDelegate:(id<KTControllerDelegate>)del;

-(IBAction)nextPanel:(id)sender;
-(IBAction)previousPanel:(id)sender;

-(void)switchToPanelForFileExtension:(NSString*)fileExtension;

@end

@protocol KTControllerDelegate <NSObject>

-(void)kt_insertString:(NSString*)string;

-(BOOL)kt_enableButtonWithSelector:(SEL)sel;

@optional
-(void)kt_leftArrow:(id)sender;
-(void)kt_rightArrow:(id)sender;
-(void)kt_upArrow:(id)sender;
-(void)kt_downArrow:(id)sender;

-(void)kt_executeLine:(id)sender;
-(void)kt_execute:(id)sender;
-(void)kt_source:(id)sender;
@end