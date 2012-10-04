//
//  MacSessionView.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/3/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MacSessionView : AMControlledView
@property (nonatomic, strong) IBOutlet NSView *leftView;
@property (nonatomic, strong) IBOutlet NSView *editorView;
@property (nonatomic, strong) IBOutlet NSView *outputView;
@property (nonatomic) CGFloat editorWidth; //for saving in session data
@property (nonatomic, readonly) BOOL leftViewVisible;

-(void)embedOutputView:(NSView*)outputView;
-(IBAction)toggleLeftView:(id)sender;
@end
