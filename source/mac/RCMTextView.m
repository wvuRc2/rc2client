//
//  RCMTextView.m
//  MacClient
//
//  Created by Mark Lilback on 10/16/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCMTextView.h"
#import "RCMAppConstants.h"

@interface RCMTextView()
@property (nonatomic, strong) NSMutableSet *kvoTokens;
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
	[self.textContainer setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[self.textContainer setWidthTracksTextView:NO];
	[self setHorizontallyResizable:YES];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fontPrefsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
	[self fontPrefsChanged:nil];
}

-(void)dealloc
{
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
}

-(void)viewDidMoveToWindow
{
	if (nil == self.window) {
		[self.kvoTokens removeAllObjects];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];		
	} else {
		__unsafe_unretained RCMTextView *blockSelf = self;
		NSUserDefaultsController *dc = [NSUserDefaultsController sharedUserDefaultsController];
		[self.kvoTokens addObject:[dc addObserverForKeyPath:[@"values." stringByAppendingString:kPref_EditorFont] task:^(id obj, NSDictionary *change) {
			[blockSelf fontPrefsChanged:nil];
		}]];
		[self.kvoTokens addObject:[dc addObserverForKeyPath:[@"values." stringByAppendingString:kPref_EditorBGColor] task:^(id obj, NSDictionary *change) {
			[blockSelf fontPrefsChanged:nil];
		}]];
		[self.kvoTokens addObject:[dc addObserverForKeyPath:[@"values." stringByAppendingString:kPref_EditorFontColor] task:^(id obj, NSDictionary *change) {
			[blockSelf fontPrefsChanged:nil];
		}]];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fontPrefsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
	}
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
	NSFont *fnt = [[NSUserDefaults standardUserDefaults] unarchiveObjectForKey:kPref_EditorFont];
	if (nil == fnt)
		fnt = [NSFont userFixedPitchFontOfSize:12.0];
	[super setString:string];
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
			NSColor *hcolor = [NSColor colorWithHexString:@"cccccc"];
			[self.textStorage addAttribute:NSBackgroundColorAttributeName value:hcolor range:openRange];
			[self.textStorage addAttribute:NSBackgroundColorAttributeName value:hcolor range:closeRange];
			RunAfterDelay(0.2, ^{
				[self.textStorage removeAttribute:NSBackgroundColorAttributeName range:openRange];
				[self.textStorage removeAttribute:NSBackgroundColorAttributeName range:closeRange];
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

@synthesize textAttributes;
@end

