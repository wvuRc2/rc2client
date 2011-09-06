//
//  KeyboardView.h
//  rc2-iPad
//
//  Created by Mark Lilback on 8/5/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

@protocol KeyboardViewDelegate;

typedef enum {
	eKeyboardStyle_Default,
	eKeyboardStyle_LeftHanded
} eKeyboardStyle;

@interface KeyboardView : UIView {
}
@property (nonatomic, retain) IBOutlet UIView *buttonTemplate;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, assign) id<KeyboardViewDelegate> delegate;
@property (nonatomic, assign) eKeyboardStyle keyboardStyle;
-(IBAction)doKeyPress:(id)sender;

//should be called after setting the keyboard style
//if null, uses builtin keyboards based on lefty pref.
//to use a custom keyboard, change 1 or both paths
-(void)layoutKeyboard:(NSString*)keyPath1 secondary:(NSString*)keyPath2;
@end

@protocol KeyboardViewDelegate <NSObject>
-(void)handkeKeyCode:(unichar)code;
@end
