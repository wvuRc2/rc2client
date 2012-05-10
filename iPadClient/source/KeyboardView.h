//
//  KeyboardView.h
//  rc2-iPad
//
//  Created by Mark Lilback on 8/5/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

@protocol KeyboardViewDelegate;
@protocol KeyboardExecuteDelegate;

typedef enum {
	eKeyboardStyle_Default,
	eKeyboardStyle_LeftHanded
} eKeyboardStyle;

@interface KeyboardView : UIView {
}
@property (nonatomic, strong) IBOutlet UIView *buttonTemplate;
@property (nonatomic, weak) IBOutlet UITextField *consoleField;
@property (nonatomic, unsafe_unretained) id<KeyboardViewDelegate> delegate;
@property (nonatomic, unsafe_unretained) id<KeyboardExecuteDelegate> executeDelegate;
@property (nonatomic, assign) eKeyboardStyle keyboardStyle;
@property (nonatomic, assign) BOOL isLandscape;
-(IBAction)doKeyPress:(id)sender;

//should be called after setting the keyboard style
-(void)layoutKeyboard;
@end

@protocol KeyboardExecuteDelegate <NSObject>
-(void)handleKeyCode:(unichar)code;
@end

@protocol KeyboardViewDelegate <NSObject>
-(void)handleKeyCode:(unichar)code;
-(void)keyboardWants2ReplaceCharactersInRange:(NSRange)rng with:(NSString*)str;
-(void)keyboardWants2DeleteCharactersInRange:(NSRange)rng;
-(NSRange)keyboardWants2GetRange;
-(void)keyboardWants2SetRange:(NSRange)rng;
-(NSString*)keyboardWantsContentString;
-(void)keyboardWants2DismissFirstResponder;
@end
