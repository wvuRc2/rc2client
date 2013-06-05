//
//  RCMTextView.m
//  MacClient
//
//  Created by Mark Lilback on 10/16/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCMTextView.h"
#import "RCMAppConstants.h"
#import "ThemeEngine.h"

@interface RCMTextView() {
	NSRange _lastLineRange;
}
@property (nonatomic, strong) NSColor *selColor;
-(NSUInteger)findMatchingParen:(NSUInteger)closeLoc string:(NSString*)str;
@end

@implementation RCMTextView

-(void)awakeFromNib
{
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	id fontName =[prefs objectForKey:kPref_EditorFont];
	if (![fontName isKindOfClass:[NSString class]])
		fontName = @"Menlo";
	CGFloat fntSize = [prefs floatForKey:kPref_EditorFontSize];
	if ((fntSize < 9) || (fntSize > 72))
		fntSize = 13;
	NSFont *fnt = [NSFont fontWithName:fontName size:fntSize];
	if (nil == fnt)
		fnt = [NSFont userFixedPitchFontOfSize:12.0];
	[self setFont:fnt];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kPref_EditorWordWrap]) {
		[self.textContainer setWidthTracksTextView:YES];
		[self setHorizontallyResizable:NO];
	} else {
		[self.textContainer setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
		[self.textContainer setWidthTracksTextView:NO];
		[self setHorizontallyResizable:YES];
	}
	[self setAutomaticSpellingCorrectionEnabled:NO];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fontPrefsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
	[self fontPrefsChanged:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionDidChange:) name:NSTextViewDidChangeSelectionNotification object:self];
	//listen for changes to selection color
	__unsafe_unretained RCMTextView *bself = self;
	ThemeEngine *te = [ThemeEngine sharedInstance];
	self.selColor = [[te currentTheme] colorForKey:@"TextSelectionColor"];
	[te registerThemeChangeObserver:self block:^(Theme *t) {
		bself.selColor = [t colorForKey:@"TextSelectionColor"];
		[bself selectionDidChange:nil];
	}];
}

-(void)dealloc
{
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTextViewDidChangeSelectionNotification object:nil];
}

-(void)viewDidMoveToWindow
{
	if (nil == self.window) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];		
	} else {
		__unsafe_unretained RCMTextView *blockSelf = self;
		NSUserDefaultsController *dc = [NSUserDefaultsController sharedUserDefaultsController];
		[self observeTarget:dc keyPath:[@"values." stringByAppendingString:kPref_EditorFont] selector:@selector(fontPrefsChanged:) userInfo:nil options:0];
		[self observeTarget:dc keyPath:[@"values." stringByAppendingString:kPref_EditorBGColor] selector:@selector(fontPrefsChanged:) userInfo:nil options:0];
		[self observeTarget:dc keyPath:[@"values." stringByAppendingString:kPref_EditorFontColor] selector:@selector(fontPrefsChanged:) userInfo:nil options:0];
	}
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SEL action = menuItem.action;
	if (action == @selector(toggleWordWrap:)) {
		menuItem.state = self.wordWrapEnabled ? NSOnState : NSOffState;
		return YES;
	}
	return [super validateMenuItem:menuItem];
}

-(void)print:(id)sender
{
	id del = self.delegate;
	if ([del respondsToSelector:@selector(handleTextViewPrint:)]) {
		[del handleTextViewPrint:sender];
		return;
	}
	[super print:sender];
}

-(void)setString:(NSString *)string
{
	if (nil == string)
		string = @"";
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSString *fntName = [defs objectForKey:kPref_EditorFont];
	CGFloat fntSize = [defs doubleForKey:kPref_EditorFontSize];
	NSFont *fnt = [NSFont fontWithName:fntName size:fntSize];
	if (nil == fnt)
		fnt = [NSFont userFixedPitchFontOfSize:12.0];
	//always have a newline at the end
	if (![string hasSuffix:@"\n"])
		string = [string stringByAppendingString:@"\n"];
	[super setString:string];
	RunAfterDelay(0.5,  ^{
		[self.enclosingScrollView.verticalRulerView setNeedsDisplay:YES];
	});
//	[self.textStorage addAttribute:NSFontAttributeName value:fnt range:NSMakeRange(0, string.length)];
}

- (NSUInteger)validModesForFontPanel:(NSFontPanel *)fontPanel
{
	return NSFontPanelFaceModeMask|NSFontPanelSizeModeMask|NSFontPanelCollectionModeMask|NSFontPanelTextColorEffectModeMask|NSFontPanelDocumentColorEffectModeMask;
}

-(void)insertText:(id)newText
{
	NSRange curLoc = self.selectedRange;
	[super insertText:newText];
	if ([@")" isEqualToString:newText])
	{
		NSString *txt = self.textStorage.string;
		NSUInteger openLoc = [self findMatchingParen:self.selectedRange.location-2 string:txt];
		if (openLoc != NSNotFound) {
			//flash the inserted character and it's matching item
			NSRange closeRange = NSMakeRange(curLoc.location, 1);
			NSRange openRange = NSMakeRange(openLoc, 1);
			NSColor *hcolor = [NSColor colorWithHexString:@"999999"];
			[self.layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName value:hcolor forCharacterRange:openRange];
			[self.layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName value:hcolor forCharacterRange:closeRange];
			RunAfterDelay(0.2, ^{
				[self.layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:openRange];
				[self.layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:closeRange];
			});
		}
	}
}

-(void)insertNewline:(id)sender
{
//	if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefAutoIndent]) {
		NSString *toInsert = @"\n";
		NSString *txt = self.textStorage.string;
		NSInteger curLoc = self.selectedRange.location;
		NSRange rng = [txt rangeOfString:@"\n" options:NSBackwardsSearch range:NSMakeRange(0, curLoc)];
		if (NSNotFound != rng.location) {
			rng.length=0;
			rng.location++;
			NSInteger i = rng.location;
			while (i < curLoc && ([txt characterAtIndex:i] == ' ' || [txt characterAtIndex:i] == '\t'))
			{
				i++;
				rng.length++;
			}
			if (rng.length > 0)
				toInsert = [toInsert stringByAppendingString:[txt substringWithRange:rng]];
		}
		[self.textStorage replaceCharactersInRange:self.selectedRange withString:toInsert];
//	} else {
//		[super insertNewline:sender];
//	}
}

-(void)selectionDidChange:(NSNotification*)note
{
	if (_lastLineRange.length)
		[self.layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:_lastLineRange];
	_lastLineRange = [self.textStorage.string paragraphRangeForRange:self.selectedRange];
	if (_lastLineRange.length)
		[self.layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName value:self.selColor forCharacterRange:_lastLineRange];
}


-(NSUInteger)findMatchingParen:(NSUInteger)closeLoc string:(NSString*)str
{
	NSInteger stackCount=0;
	NSUInteger curLoc = closeLoc;
	while (curLoc > 0) {
		if ([str characterAtIndex:curLoc] == '(') {
			if (stackCount == 0)
				return curLoc;
			stackCount--;
		} else if ([str characterAtIndex:curLoc] == ')') {
			stackCount++;
			if (stackCount < 0)
				return NSNotFound;
		}
		curLoc--;
	}
	
	return NSNotFound;
}

-(void)fontPrefsChanged:(NSNotification*)note
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSColor *fgcolor = [NSColor colorWithHexString:[defaults objectForKey:kPref_EditorFontColor]];
	NSColor *bgcolor = [NSColor colorWithHexString:[defaults objectForKey:kPref_EditorBGColor]];
	id fontName =[defaults objectForKey:kPref_EditorFont];
	if (![fontName isKindOfClass:[NSString class]])
		fontName = @"Menlo";
	CGFloat fntSize = [defaults floatForKey:kPref_EditorFontSize];
	if ((fntSize < 9) || (fntSize > 72))
		fntSize = 13;
	NSFont *font = [NSFont fontWithName:fontName size:fntSize];
	if (nil == font)
		font = [NSFont userFixedPitchFontOfSize:12.0];
	self.textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
						   fgcolor, NSForegroundColorAttributeName, 
						   bgcolor, NSBackgroundColorAttributeName, 
						   nil];
	[self setTypingAttributes:self.textAttributes];
	self.backgroundColor = bgcolor;
	[(id)self.delegate recolorText];
}

-(IBAction)toggleWordWrap:(id)sender
{
	if (self.textContainer.widthTracksTextView) {
		self.textContainer.widthTracksTextView = NO;
		self.textContainer.containerSize = NSMakeSize(FLT_MAX, FLT_MAX);
		[self setHorizontallyResizable:YES];
	} else {
		self.textContainer.containerSize = NSMakeSize(200, FLT_MAX);
		self.textContainer.widthTracksTextView = YES;
	}
	[self didChangeText];
	[self.enclosingScrollView.verticalRulerView setNeedsDisplay:YES];
	[[NSUserDefaults standardUserDefaults] setBool:self.wordWrapEnabled forKey:kPref_EditorWordWrap];
}

-(BOOL)wordWrapEnabled
{
	return self.textContainer.widthTracksTextView;
}

@synthesize textAttributes;
@end

