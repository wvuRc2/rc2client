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
@property (nonatomic, assign) BOOL isLandscape;
-(IBAction)doKeyPress:(id)sender;

//should be called after setting the keyboard style
-(void)layoutKeyboard;
@end

@protocol KeyboardViewDelegate <NSObject>
-(void)handkeKeyCode:(unichar)code;
@end
