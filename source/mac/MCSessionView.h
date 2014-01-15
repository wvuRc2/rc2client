//
//  MCSessionView.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/3/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCSavedSession;

@interface MCSessionView : AMControlledView
@property (nonatomic, strong) IBOutlet NSView *leftView;
@property (nonatomic, strong) IBOutlet NSView *editorView;
@property (nonatomic, strong) IBOutlet NSView *outputView;
@property (nonatomic) CGFloat editorWidth; //for saving in session data
@property (nonatomic, copy) BasicBlock leftViewAnimationHandler;
@property (nonatomic, readonly) BOOL leftViewVisible;
@property (nonatomic, readonly) BOOL editorWidthLocked;

-(void)embedOutputView:(NSView*)outputView;
-(IBAction)toggleLeftView:(id)sender;

-(IBAction)toggleEditorWidthLock:(id)sender;

-(void)saveSessionState:(RCSavedSession*)sessionState;
-(void)restoreSessionState:(RCSavedSession*)savedState;
@end
