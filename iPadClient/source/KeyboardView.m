//
//  KeyboardView.m
//  rc2-iPad
//
//  Created by Mark Lilback on 8/5/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

/*
 	symbols/ABC button is (18, 275, 182, 60)
	 shift button is (18, 209, 88, 60)
 */

#import "KeyboardView.h"
#import "KeyButton.h"
#import "AppConstants.h"

#define kAlphaLabel @"abc"
#define kSymbolsLabel @"!?@"
#define kLayoutButtonWidthLandscape 182
#define kLayoutButtonWidthPortrait 126
#define kLayoutButtonBottomOffset 17
#define kKeyButtonMargin 6
#define kKeyButtonDefaultWidth 88
#define kKeyButtonDefaultHeight 51
#define kKeyViewYOffset 11
#define kKeyButtonDefaultFrame CGRectMake(18, kKeyViewYOffset, kKeyButtonDefaultWidth, kKeyButtonDefaultHeight)

#define kKeyCodeGets 0xea61
#define kKeyCodeDelete 0xea64
#define kKeyCodeShift 0xea65
#define kKeyCodeLayoutSwap 0xea80
#define kKeyCodeDismissKeyboard 0xea90
#define kKeyCodeUpArrow 0xeb00
#define kKeyCodeDownArrow 0xeb01
#define kKeyCodeLeftArrow 0xeb02
#define kKeyCodeRightArrow 0xeb03

enum {
	eKeyLayout_Alpha=0,
	eKeyLayout_Symbols
};

@interface KeyboardView() {
	CGGradientRef _keyGradient;
	CGGradientRef _KeyGradientPressed;
	CGFloat _lastKeyRowYOrigin;
	CGFloat _landscapeKeyboardHeight;
	CGFloat _portraitKeyboardHeight;
}
@property (nonatomic, assign) NSInteger currentLayout;
@property (nonatomic, retain) UIView *alphaKeyView;
@property (nonatomic, retain) UIView *symKeyView;
@property (nonatomic, retain) UIView *pAlphaKeyView;
@property (nonatomic, retain) UIView *pSymKeyView;
@property (nonatomic, assign) UIView *currentAlphaKeyView;
@property (nonatomic, assign) UIView *currentSymKeyView;
@property (nonatomic, retain) NSData *buttonTemplateData;
@property (nonatomic, retain) KeyButton *layoutButton;
@property (nonatomic, assign) KeyButton *shiftKey;
@property (nonatomic, assign) BOOL shiftDown;
-(void)cacheGradients;
-(void)flushGradients;
-(IBAction)doLayoutKey:(id)sender;
-(void)adjustFrame;
-(void)adjustKeysForCurrentOrientation;
-(NSString*)fontNameForTag:(NSInteger)tag;
//returns the height of the keyboard
-(CGFloat)loadKeyFile:(NSString*)keyFilePath intoView:(UIView*)theView;
-(UIImage*)imageForKey:(NSString*)keyStr size:(CGSize)sizes fontName:(NSString*)fontName pressed:(BOOL)pressed;
@end

@implementation KeyboardView
@synthesize keyboardStyle=_keyStyle;
@synthesize isLandscape=_isLandscape;

-(id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		self.isLandscape = [aDecoder decodeBoolForKey:@"RC2IsLandscape"];
		self.keyboardStyle = [aDecoder decodeIntegerForKey:@"RC2KeyboardStyle"];
	}
	return self;
}

-(void)dealloc
{
	self.alphaKeyView=nil;
	self.symKeyView=nil;
	self.pAlphaKeyView=nil;
	self.pSymKeyView=nil;
	[self flushGradients];
	[super dealloc];
}

-(void)awakeFromNib
{
	[self cacheGradients];
	self.isLandscape=UIInterfaceOrientationIsLandscape(TheApp.statusBarOrientation);
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeInteger:self.keyboardStyle forKey:@"RC2KeyboardStyle"];
	[aCoder encodeBool:self.isLandscape forKey:@"RC2IsLandscape"];
}

-(void)layoutKeyboard
{
	CGRect vframe = self.frame;
	vframe.origin = CGPointZero;
	UIView *aView = [[UIView alloc] initWithFrame:vframe];
	self.alphaKeyView = aView;
	aView.opaque=NO;
	aView.userInteractionEnabled=YES;
	[aView release];
	aView = [[UIView alloc] initWithFrame:vframe];
	self.symKeyView = aView;
	aView.opaque=NO;
	aView.alpha = 0;
	[aView release];
	aView = [[UIView alloc] initWithFrame:vframe];
	self.pAlphaKeyView = aView;
	aView.opaque=NO;
	[aView release];
	aView = [[UIView alloc] initWithFrame:vframe];
	self.pSymKeyView = aView;
	aView.opaque=NO;
	aView.alpha = 0;
	[aView release];
	self.currentAlphaKeyView = self.alphaKeyView;
	self.currentSymKeyView = self.symKeyView;

	if (nil == self.buttonTemplateData) {
		self.buttonTemplateData = [NSKeyedArchiver archivedDataWithRootObject:self.buttonTemplate];
		[self.buttonTemplate removeFromSuperview];
		self.buttonTemplate=nil;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSFileManager *fm = [NSFileManager defaultManager];
	_landscapeKeyboardHeight = [self loadKeyFile:[defaults objectForKey:kPrefCustomKey1URL] intoView:self.alphaKeyView];
	[self loadKeyFile:[defaults objectForKey:kPrefCustomKey2URL] intoView:self.symKeyView];
	_portraitKeyboardHeight = _landscapeKeyboardHeight; //default
	[self addSubview:self.alphaKeyView];
	[self addSubview:self.symKeyView];
	NSString *ppath = [[[defaults objectForKey:kPrefCustomKey1URL] stringByDeletingPathExtension] stringByAppendingString:@"p.txt"];
	if ([fm fileExistsAtPath:ppath]) {
		_portraitKeyboardHeight = [self loadKeyFile:ppath intoView:self.pAlphaKeyView];
	} else {
		self.pAlphaKeyView = self.alphaKeyView;
	}
	ppath = [[[defaults objectForKey:kPrefCustomKey2URL] stringByDeletingPathExtension] stringByAppendingString:@"p.txt"];
	if ([fm fileExistsAtPath:ppath]) {
		[self loadKeyFile:ppath intoView:self.pSymKeyView];
	} else {
		self.pSymKeyView = self.symKeyView;
	}
	
	KeyButton *aButton = [NSKeyedUnarchiver unarchiveObjectWithData:self.buttonTemplateData];
	aButton.frame = CGRectMake(18, _lastKeyRowYOrigin, kLayoutButtonWidthLandscape, kKeyButtonDefaultHeight);
	self.layoutButton = aButton;
	aButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
	[aButton setTitle:kSymbolsLabel forState:UIControlStateNormal];
	[aButton setBackgroundImage:[self imageForKey:@" " size:aButton.frame.size fontName:[self fontNameForTag:0] pressed:NO] 
					   forState:UIControlStateNormal];
	[aButton setBackgroundImage:[self imageForKey:@" " size:aButton.frame.size fontName:[self fontNameForTag:0] pressed:YES] 
					   forState:UIControlStateHighlighted];
	[aButton addTarget:self action:@selector(doLayoutKey:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:aButton];
	[self bringSubviewToFront:aButton];
	[self adjustKeysForCurrentOrientation];
//	[self adjustFrame];
}

-(CGFloat)loadKeyFile:(NSString*)keyFilePath intoView:(UIView*)theView
{
	NSString *keydata = [NSString stringWithContentsOfFile:keyFilePath encoding:NSUTF8StringEncoding error:nil];
	NSArray *rows = [keydata componentsSeparatedByString:@"\n\n"];
	
	CGRect frame = kKeyButtonDefaultFrame;
	CGRect initFrame = frame;
	
	NSInteger rowCnt=0;
	for (NSString *rowStr in rows) {
		CGFloat largestHeight=0;
		NSArray *keyStrs = [rowStr componentsSeparatedByString:@"\n"];
		if ([keyStrs count] < 1)
			continue;
		NSString *initLocStr = [keyStrs objectAtIndex:0];
		CGFloat initX = [initLocStr floatValue];
		if (initX > 0 && initX < 1000)
			frame.origin.x += initX;
		for (NSString *keyStr in [keyStrs subarrayWithRange:NSMakeRange(1, [keyStrs count]-1)]) {
			NSArray *keyData = [keyStr componentsSeparatedByString:@"::"];
			if ([keyData count] != 4)
				continue;
			CGFloat customwidth = [[keyData objectAtIndex:2] floatValue];
			if (customwidth > 0)
				frame.size.width = customwidth;
			CGFloat customheight = [[keyData objectAtIndex:3] floatValue];
			if (customheight > 0)
				frame.size.height = customheight;
			if (frame.size.height > largestHeight)
				largestHeight = frame.size.height;
			NSString *key = [keyData objectAtIndex:0];
			if ([key isEqualToString:@"colon"])
				key = @":";
			KeyButton *aButton = [NSKeyedUnarchiver unarchiveObjectWithData:self.buttonTemplateData];
			aButton.frame = frame;
			NSString *tagstr = [keyData objectAtIndex:1];
			if ([tagstr hasPrefix:@"0x"]) {
				aButton.tag = strtol([tagstr UTF8String], NULL, 16);
			}
			aButton.representedText = key;
			[aButton addTarget:self action:@selector(doKeyPress:) forControlEvents:UIControlEventTouchUpInside];
			[theView addSubview:aButton];
			if ([key hasPrefix:@"@"] && [key length] > 1) {
				//we use an image instead of a string
				[aButton setImage:[UIImage imageNamed:[key substringFromIndex:1]] forState:UIControlStateNormal];
				UIImage *himg = [UIImage imageNamed:[[key substringFromIndex:1] stringByAppendingString:@"Highlighted"]];
				if (himg)
					[aButton setImage:himg forState:UIControlStateSelected];
				key = @"";
			}
			if (aButton.tag == 0xea65)
				self.shiftKey = aButton;
			NSString *fontName = [self fontNameForTag:aButton.tag];
			UIImage *regImg = [self imageForKey:key size:frame.size fontName:fontName pressed:NO];
			UIImage *pressImg = [self imageForKey:key size:frame.size fontName:fontName pressed:YES];
			[aButton setBackgroundImage:regImg forState:UIControlStateNormal];
			[aButton setBackgroundImage:pressImg forState:UIControlStateHighlighted];
			frame.origin.x += frame.size.width + kKeyButtonMargin;
			frame.size = initFrame.size;
		}
		//move frame.orign.y to the the next row
		_lastKeyRowYOrigin = frame.origin.y;
		if (largestHeight < 60)
			frame.origin.y += 6 + largestHeight;
		else
			frame.origin.y += initFrame.size.height + kKeyButtonMargin;
		frame.origin.x = initFrame.origin.x;
		rowCnt++;
	}
	return frame.origin.y + kKeyViewYOffset;
}


-(void)drawRect:(CGRect)rect
{
	CGFloat locs[2] = {0,1};
	CGFloat colors[8] = {0.61, 0.61, 0.66, 1.0, 0.26, 0.26, 0.29, 1.0};
	CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradient = CGGradientCreateWithColorComponents(cspace, colors, locs, 2);
	CGColorSpaceRelease(cspace);
	
	CGContextRef c = UIGraphicsGetCurrentContext();
	CGContextDrawLinearGradient(c, gradient, CGPointMake(0, 0), CGPointMake(0, rect.size.height), 0);
	CGGradientRelease(gradient);
}

-(IBAction)doLayoutKey:(id)sender
{
	if (self.currentLayout == eKeyLayout_Alpha) {
		self.currentSymKeyView.alpha = 1.0;
		self.currentAlphaKeyView.alpha = 0;
		self.currentLayout = eKeyLayout_Symbols;
		[self.layoutButton setTitle:kAlphaLabel forState:UIControlStateNormal];
		[self.layoutButton setNeedsDisplay];
	} else {
		self.currentSymKeyView.alpha = 0;
		self.currentAlphaKeyView.alpha = 1.0;
		self.currentLayout = eKeyLayout_Alpha;
		[self.layoutButton setTitle:kSymbolsLabel forState:UIControlStateNormal];
		[self.layoutButton setNeedsDisplay];
	}
}

-(void)toggleShift
{
	self.shiftDown = !self.shiftDown;
	self.shiftKey.selected = self.shiftDown;
}

-(IBAction)doKeyPress:(KeyButton*)sender
{
	NSString *str=nil;
	BOOL isConsole = [self.consoleField isFirstResponder];
	NSRange rng = self.textView.selectedRange;
	NSString *curText = isConsole ? self.consoleField.text : self.textView.text;
	if ([sender tag] == 0) {
		str = self.shiftDown ? sender.representedText : [sender.representedText lowercaseString];
	} else if ([sender tag] >= 1000) {
		switch ([sender tag]) {
			case kKeyCodeGets:
				str = @"<-";
				break;
			case kKeyCodeDelete:
				if (isConsole) {
					self.consoleField.text = [curText substringToIndex:curText.length-2];
				} else if (rng.location > 0) {
					self.textView.text = [curText stringByReplacingCharactersInRange:NSMakeRange(rng.location-1, 1) withString:@""];
					self.textView.selectedRange = NSMakeRange(rng.location-1, 0);
				}
				break;
			case kKeyCodeShift:
				[self toggleShift];
				break;
			case kKeyCodeLayoutSwap:
				sender.selected = !sender.selected;
				self.currentLayout = sender.selected ? eKeyLayout_Alpha : eKeyLayout_Symbols;
				break;
			case kKeyCodeDismissKeyboard:
				if (isConsole)
					[self.consoleField resignFirstResponder];
				else
					[self.textView resignFirstResponder];
				break;
			case kKeyCodeUpArrow:
				break;
			case kKeyCodeDownArrow:
				break;
			case kKeyCodeLeftArrow:
				if (!isConsole && rng.location > 0)
					self.textView.selectedRange = NSMakeRange(rng.location-1, 0);
				break;
			case kKeyCodeRightArrow:
				if (!isConsole && rng.location < [curText length])
					self.textView.selectedRange = NSMakeRange(rng.location+1, 0);
				break;
			default:
				[self.delegate handleKeyCode:(unichar)[sender tag]];
				break;
		}
	} else {
		str = [NSString stringWithFormat:@"%c", [sender tag]];
	}
	if (str) {
		if (isConsole)
			self.consoleField.text = [curText stringByAppendingString:str];
		else
			[self.textView setText:[curText stringByReplacingCharactersInRange:rng withString:str]];
	}
}

-(void)cacheGradients
{
	CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
	CGFloat locations[2] = {0.0, 1.0};
	CGFloat components[8] = { 0.933, 0.933, 0.941, 1.000,
		0.827, 0.827, 0.851, 1.000 };	
	CGFloat componentsPressed[8] = { 0.690, 0.698, 0.725, 1.000,  
		0.514, 0.522, 0.140, 1.000 };
	_keyGradient = CGGradientCreateWithColorComponents(cspace, components, locations, 2);
	_KeyGradientPressed = CGGradientCreateWithColorComponents(cspace, componentsPressed, locations, 2);
	CGColorSpaceRelease(cspace);
}

-(void)flushGradients
{
	if (_keyGradient) {
		CGGradientRelease(_keyGradient);
		_keyGradient=nil;
	}
	if (_KeyGradientPressed) {
		CGGradientRelease(_KeyGradientPressed);
		_KeyGradientPressed=nil;
	}
}

-(NSString*)fontNameForTag:(NSInteger)tag
{
	if (tag < 0xEA60)
		return @"Helvetica";
//	switch (tag) {
//		case 0xea64:
//			return @"AppleGothic";
//	}
	return @"Helvetica";
}

-(UIImage*)imageForKey:(NSString*)keyStr size:(CGSize)sizes fontName:(NSString*)fontName pressed:(BOOL)pressed
{
	UIGraphicsBeginImageContextWithOptions(sizes, NO, 1.0);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGRect bframe = CGRectMake(3, 2, 78, 73);
	bframe.size = sizes;
	bframe = CGRectInset(bframe, 3, 3);
	UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:bframe cornerRadius:6];
	
	CGContextSetShadow(ctx, CGSizeMake(-1, 3), 8.0);
	CGContextAddPath(ctx, path.CGPath);
	CGContextFillPath(ctx);
	
	CGPoint start = CGPointMake(CGRectGetMidX(bframe), CGRectGetMinY(bframe));
	CGPoint end = CGPointMake(CGRectGetMidX(bframe), CGRectGetMaxY(bframe));
	CGContextAddPath(ctx, path.CGPath);
	CGContextClip(ctx);
	CGContextDrawLinearGradient(ctx, pressed ? _KeyGradientPressed : _keyGradient, start, end, 0);
	
	if ([keyStr length] > 0) {
		UIFont *fnt = [UIFont fontWithName:fontName size:24.0];
		CGRect txtRect = CGRectZero;
		txtRect.size = [keyStr sizeWithFont:fnt];
		txtRect.origin.x = floor((bframe.size.width - txtRect.size.width) / 2) + bframe.origin.x;
		txtRect.origin.y = floor((bframe.size.height - txtRect.size.height) / 2) + bframe.origin.y;
		[keyStr drawInRect:txtRect withFont:fnt lineBreakMode:UILineBreakModeClip];
	}
	
	return UIGraphicsGetImageFromCurrentImageContext();
}

-(void)setIsLandscape:(BOOL)newOrient
{
	if (newOrient == _isLandscape)
		return;
	_isLandscape = newOrient;
	[self adjustKeysForCurrentOrientation];
}

-(void)adjustKeysForCurrentOrientation
{
	UIView *targetView1 = _isLandscape ? self.alphaKeyView : self.pAlphaKeyView;
	UIView *targetView2 = _isLandscape ? self.symKeyView : self.pSymKeyView;
	if (self.currentAlphaKeyView != targetView1) {
		[self.currentAlphaKeyView removeFromSuperview];
		[self insertSubview:targetView1 belowSubview:self.layoutButton];
		self.currentAlphaKeyView = targetView1;
	}
	if (self.currentSymKeyView != targetView2) {
		[self.currentSymKeyView removeFromSuperview];
		[self insertSubview:targetView2 belowSubview:self.layoutButton];
		self.currentSymKeyView = targetView2;
	}
	//a hack to make sure the alpha is correct
	self.currentLayout = !self.currentLayout;
	[self doLayoutKey:self];
	[self adjustFrame];
}

-(void)adjustFrame
{
	CGRect f = self.frame;
	NSLog(@"our frame is %@", NSStringFromCGRect(f));
	NSLog(@"super frame is %@", NSStringFromCGRect(self.superview.frame));
	f.size.height = _isLandscape ? _landscapeKeyboardHeight : _portraitKeyboardHeight;
	if (f.size.height < 100) //we were getting zero at some point. this corrects that problem
		f.size.height = 357;
	self.frame = f;
	//simulator doesn't have a displacement problem, but device does.
/* //i think this was fixed in ios 5
#ifdef TARGET_OS_IPHONE
	CGRect sf = self.superview.frame;
	sf.origin.y = _isLandscape ? 768 - _landscapeKeyboardHeight : 1024 - _portraitKeyboardHeight;
	sf.size.height = f.size.height;
	self.superview.frame = sf;
#endif
 */
	CGRect lf = self.layoutButton.frame;
	lf.origin.y = f.size.height - kKeyButtonDefaultHeight - kLayoutButtonBottomOffset;
	lf.size.width = _isLandscape ? kLayoutButtonWidthLandscape : kLayoutButtonWidthPortrait;
	self.layoutButton.frame = lf; 
}

#pragma mark - synthesizers

@synthesize currentLayout;
@synthesize alphaKeyView;
@synthesize symKeyView;
@synthesize buttonTemplateData;
@synthesize layoutButton;
@synthesize textView;
@synthesize delegate;
@synthesize buttonTemplate;
@synthesize shiftDown;
@synthesize shiftKey;
@synthesize pSymKeyView;
@synthesize pAlphaKeyView;
@synthesize currentSymKeyView;
@synthesize currentAlphaKeyView;
@synthesize consoleField;
@end
