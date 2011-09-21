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

#define kSymbolsLabel @"!?@"

enum {
	eKeyLayout_Alpha=0,
	eKeyLayout_Symbols
};

@interface KeyboardView() {
	CGGradientRef _keyGradient;
	CGGradientRef _KeyGradientPressed;
	CGFloat _lastKeyRowYOrigin;
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
-(NSString*)fontNameForTag:(NSInteger)tag;
-(void)loadKeyFile:(NSString*)keyFilePath intoView:(UIView*)theView;
-(UIImage*)imageForKey:(NSString*)keyStr size:(CGSize)sizes fontName:(NSString*)fontName pressed:(BOOL)pressed;
@end

@implementation KeyboardView
@synthesize keyboardStyle=_keyStyle;
@synthesize isLandscape=_isLandscape;

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
	self.isLandscape=YES;
}

-(void)layoutKeyboard
{
	CGRect vframe = self.frame;
	vframe.origin = CGPointZero;
	UIView *aView = [[UIView alloc] initWithFrame:vframe];
	self.alphaKeyView = aView;
	aView.opaque=NO;
	[aView release];
	aView = [[UIView alloc] initWithFrame:vframe];
	self.symKeyView = aView;
	aView.opaque=NO;
	aView.alpha = 0;
	[aView release];
	aView = [[UIView alloc] initWithFrame:vframe];
	self.pAlphaKeyView = aView;
	aView.opaque=NO;
	aView.alpha = 0;
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
	[self loadKeyFile:[defaults objectForKey:kPrefCustomKey1URL] intoView:self.alphaKeyView];
	[self loadKeyFile:[defaults objectForKey:kPrefCustomKey2URL] intoView:self.symKeyView];
	[self addSubview:self.alphaKeyView];
	[self addSubview:self.symKeyView];
	NSString *ppath = [[[defaults objectForKey:kPrefCustomKey1URL] stringByDeletingPathExtension] stringByAppendingString:@"p.txt"];
	if ([fm fileExistsAtPath:ppath]) {
		[self loadKeyFile:ppath intoView:self.pAlphaKeyView];
		[self addSubview:self.pAlphaKeyView];
	} else {
		self.pAlphaKeyView = self.alphaKeyView;
	}
	ppath = [[[defaults objectForKey:kPrefCustomKey2URL] stringByDeletingPathExtension] stringByAppendingString:@"p.txt"];
	if ([fm fileExistsAtPath:ppath]) {
		[self loadKeyFile:ppath intoView:self.pSymKeyView];
		[self addSubview:self.pSymKeyView];
	} else {
		self.pSymKeyView = self.symKeyView;
	}
	
	KeyButton *aButton = [NSKeyedUnarchiver unarchiveObjectWithData:self.buttonTemplateData];
	aButton.frame = CGRectMake(18, _lastKeyRowYOrigin, 182, 51);
	self.layoutButton = aButton;
	[aButton setTitle:kSymbolsLabel forState:UIControlStateNormal];
	[aButton setBackgroundImage:[self imageForKey:@" " size:aButton.frame.size fontName:[self fontNameForTag:0] pressed:NO] 
					   forState:UIControlStateNormal];
	[aButton setBackgroundImage:[self imageForKey:@" " size:aButton.frame.size fontName:[self fontNameForTag:0] pressed:YES] 
					   forState:UIControlStateHighlighted];
	[aButton addTarget:self action:@selector(doLayoutKey:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:aButton];
	[self bringSubviewToFront:aButton];
}

-(void)loadKeyFile:(NSString*)keyFilePath intoView:(UIView*)theView
{
	NSString *keydata = [NSString stringWithContentsOfFile:keyFilePath encoding:NSUTF8StringEncoding error:nil];
	NSArray *rows = [keydata componentsSeparatedByString:@"\n\n"];
	
	CGRect frame = CGRectMake(18, 11, 88, 51);
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
			frame.origin.x += frame.size.width + 6;
			frame.size = initFrame.size;
		}
		//move frame.orign.y to the the next row
		_lastKeyRowYOrigin = frame.origin.y;
		if (largestHeight < 60)
			frame.origin.y += 6 + largestHeight;
		else
			frame.origin.y += initFrame.size.height + 6;
		frame.origin.x = initFrame.origin.x;
		rowCnt++;
	}
	CGRect viewFrame = self.frame;
	viewFrame.size.height = frame.origin.y + 11;
	self.frame = viewFrame;
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
}

-(IBAction)doLayoutKey:(id)sender
{
	if (self.currentLayout == eKeyLayout_Alpha) {
		self.symKeyView.alpha = 1.0;
		self.alphaKeyView.alpha = 0;
		self.currentLayout = eKeyLayout_Symbols;
		[self.layoutButton setTitle:@"abc" forState:UIControlStateNormal];
		[self.layoutButton setNeedsDisplay];
	} else {
		self.symKeyView.alpha = 0;
		self.alphaKeyView.alpha = 1.0;
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
	NSRange rng = self.textView.selectedRange;
	NSString *curText = self.textView.text;
	if ([sender tag] == 0) {
		str = self.shiftDown ? sender.representedText : [sender.representedText lowercaseString];
	} else if ([sender tag] >= 1000) {
		switch ([sender tag]) {
			case 0xea61: // <-
				str = @"<-";
				break;
			case 0xEA64: //delete
				if (rng.location > 0) {
					self.textView.text = [curText stringByReplacingCharactersInRange:NSMakeRange(rng.location-1, 1) withString:@""];
					self.textView.selectedRange = NSMakeRange(rng.location-1, 0);
				}
				break;
			case 0xea65: //shift
				[self toggleShift];
				break;
			case 0xea80: //switch keyboard
				sender.selected = !sender.selected;
				self.currentLayout = sender.selected ? eKeyLayout_Alpha : eKeyLayout_Symbols;
				break;
			case 0xea90:
				[self.textView resignFirstResponder];
				break;
			case 0xeb00: //up arrow
				break;
			case 0xeb01: //down arrow
				break;
			case 0xeb02: //left arrow
				if (rng.location > 0)
					self.textView.selectedRange = NSMakeRange(rng.location-1, 0);
				break;
			case 0xeb03: //right arrow
				if (rng.location < [curText length])
					self.textView.selectedRange = NSMakeRange(rng.location+1, 0);
				break;
			default:
				[self.delegate handkeKeyCode:(unichar)[sender tag]];
				break;
		}
	} else {
		str = [NSString stringWithFormat:@"%c", [sender tag]];
	}
	if (str) {
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
	_isLandscape = newOrient;
	self.currentAlphaKeyView.alpha = 0;
	self.currentSymKeyView.alpha = 0;
	if (newOrient) {
		self.currentAlphaKeyView = self.alphaKeyView;
		self.currentSymKeyView = self.symKeyView;
	} else {
		self.currentAlphaKeyView = self.pAlphaKeyView;
		self.currentSymKeyView = self.pSymKeyView;
	}
	self.currentAlphaKeyView.alpha = 1;
	self.currentSymKeyView.alpha = 1;
}

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
@end
