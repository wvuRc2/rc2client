//
//  SessionEditView.m
//  Rc2Client
//
//  Created by Mark Lilback on 5/7/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "SessionEditView.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "SessionEditorLayoutManager.h"

#define kLineNumberGutterWidth 40

@interface SessionEditView ()
@property (readwrite) BOOL isBecomingFirstResponder;
@end

@implementation SessionEditView

-(void)keyboardVisible:(NSNotification*)note
{
	BOOL isLand = UIInterfaceOrientationIsLandscape(TheApp.statusBarOrientation);
	if (isLand) {
		NSDictionary *userInfo = [note userInfo];
		CGSize kbsize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
		UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, kbsize.width, 0);
		self.contentInset = insets;
		self.scrollIndicatorInsets = insets;
	}
}

-(void)keyboardHiding:(NSNotification*)note
{
	self.contentInset = UIEdgeInsetsZero;
	self.scrollIndicatorInsets = UIEdgeInsetsZero;
}

-(id)initWithFrame:(CGRect)frame
{
	NSTextStorage *ts = [[NSTextStorage alloc] init];
	SessionEditorLayoutManager *lm = [[SessionEditorLayoutManager alloc] init];
	NSTextContainer *tc = [[NSTextContainer alloc] initWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
	
	tc.widthTracksTextView = YES;
	tc.exclusionPaths = @[[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, kLineNumberGutterWidth+8, CGFLOAT_MAX)]];
	[lm addTextContainer:tc];
	[ts addLayoutManager:lm];
	
	if ((self = [super initWithFrame:frame textContainer:tc])) {
		self.contentMode = UIViewContentModeRedraw;
		UIMenuController *mc = [UIMenuController sharedMenuController];
		mc.menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Execute" action:@selector(executeSelection:)],
							  [[UIMenuItem alloc] initWithTitle:@"Help" action:@selector(showHelp:)]];
		[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardVisible:)
												 name:UIKeyboardDidShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(keyboardHiding:)
												 name:UIKeyboardWillHideNotification object:nil];
		self.autocapitalizationType = UITextAutocapitalizationTypeNone;
		self.autocorrectionType = UITextAutocorrectionTypeNo;
		self.layer.masksToBounds=YES;
	}
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
/*
-(void)awakeFromNib
{
	[super awakeFromNib];
	UIMenuController *mc = [UIMenuController sharedMenuController];
	mc.menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Execute" action:@selector(executeSelection:)],
						  [[UIMenuItem alloc] initWithTitle:@"Help" action:@selector(showHelp:)]];
	[[NSNotificationCenter defaultCenter] addObserver:self
										 selector:@selector(keyboardVisible:)
											 name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
										 selector:@selector(keyboardHiding:)
											 name:UIKeyboardWillHideNotification object:nil];
	self.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.autocorrectionType = UITextAutocorrectionTypeNo;
	self.layer.masksToBounds=YES;
}
*/
-(UIView*)view
{
	return self;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
	if (action == @selector(showHelp:) || action == @selector(executeSelection:))
		return YES;
	return [super canPerformAction:action withSender:sender];
}

-(void)upArrow
{
	UITextPosition *pos = self.selectedTextRange.start;
	pos = [self positionFromPosition:pos inDirection:UITextLayoutDirectionUp offset:1];
	UITextRange *rng = [self textRangeFromPosition:pos toPosition:pos];
	self.selectedTextRange = rng;
}

-(void)downArrow
{
	UITextPosition *pos = self.selectedTextRange.start;
	pos = [self positionFromPosition:pos inDirection:UITextLayoutDirectionDown offset:1];
	UITextRange *rng = [self textRangeFromPosition:pos toPosition:pos];
	self.selectedTextRange = rng;
}

-(void)leftArrow
{
	UITextPosition *pos = self.selectedTextRange.start;
	pos = [self positionFromPosition:pos inDirection:UITextLayoutDirectionLeft offset:1];
	UITextRange *rng = [self textRangeFromPosition:pos toPosition:pos];
	self.selectedTextRange = rng;
}

-(void)rightArrow
{
	UITextPosition *pos = self.selectedTextRange.start;
	pos = [self positionFromPosition:pos inDirection:UITextLayoutDirectionRight offset:1];
	UITextRange *rng = [self textRangeFromPosition:pos toPosition:pos];
	self.selectedTextRange = rng;
}



-(IBAction)executeSelection:(id)sender
{
	if (self.executeBlock)
		self.executeBlock(self);
}

-(IBAction)showHelp:(id)sender
{
	if (self.helpBlock)
		self.helpBlock(self);
}

-(BOOL)becomeFirstResponder
{
	self.isBecomingFirstResponder = YES;
	//this is a skanky hack using private API. There appears to be no other way to hide the accessory
	// view once keyboard notifications are received.
	Class cz = NSClassFromString(@"UIKeyboardImpl");
	id keybd = objc_msgSend(cz, NSSelectorFromString(@"sharedInstance"));
	id val = [keybd valueForKey:@"inHardwareKeyboardMode"];
	if ([val boolValue])
		self.inputAccessoryView = nil;

	BOOL result = [super becomeFirstResponder];
	self.isBecomingFirstResponder = NO;
	return result;
}

-(void)drawRect:(CGRect)rect
{
	//  Drag the line number gutter background.  The line numbers them selves are drawn by LineNumberLayoutManager.
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect bounds = self.bounds;
	
	CGContextSetFillColorWithColor(context, [UIColor grayColor].CGColor);
	CGContextFillRect(context, CGRectMake(bounds.origin.x, bounds.origin.y, kLineNumberGutterWidth, bounds.size.height));
	
	CGContextSetStrokeColorWithColor(context, [UIColor darkGrayColor].CGColor);
	CGContextSetLineWidth(context, 0.5);
	CGContextStrokeRect(context, CGRectMake(bounds.origin.x + 39.5, bounds.origin.y, 0.5, CGRectGetHeight(bounds)));
	
	[super drawRect:rect];
}

@end
