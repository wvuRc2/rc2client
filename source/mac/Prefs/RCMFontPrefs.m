//
//  RCMFontPrefs.m
//  Rc2
//
//  Created by Mark Lilback on 4/10/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "RCMFontPrefs.h"
#import "RCMAppConstants.h"

@interface RCMFontPrefs()
@property (nonatomic, strong) IBOutlet NSTextField *wsheetFontField;
@property (nonatomic, strong) NSFont *wsheetFont;
@property (nonatomic, strong) NSString *wsheetFontDescription;
@end

@implementation RCMFontPrefs

-(void)loadView
{
	[super loadView];
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	//stick ourselves in the responder chain
	[self setNextResponder: [self.view nextResponder]];
	[self.view setNextResponder: self];
	id fontName = [prefs objectForKey:kPref_EditorFont];
	if (![fontName isKindOfClass:[NSString class]])
		fontName = @"Menlo";
	CGFloat fntSize = [prefs floatForKey:kPref_EditorFontSize];
	if ((fntSize < 9) || (fntSize > 72))
		fntSize = 13.0;
	self.wsheetFont = [NSFont fontWithName:fontName size:fntSize];
	self.wsheetFontField.font = self.wsheetFont;
	self.wsheetFontField.backgroundColor = [NSColor colorWithHexString:[prefs objectForKey:kPref_EditorBGColor]];
	self.wsheetFontField.textColor = [NSColor colorWithHexString:[prefs objectForKey:kPref_EditorFontColor]];
	self.wsheetFontDescription = [NSString stringWithFormat:@"%@ %1.1f",
								self.wsheetFont.fontName, self.wsheetFont.pointSize];
}

- (NSUInteger)validModesForFontPanel:(NSFontPanel *)fontPanel
{
	return NSFontPanelFaceModeMask|NSFontPanelSizeModeMask|NSFontPanelCollectionModeMask|NSFontPanelTextColorEffectModeMask|NSFontPanelDocumentColorEffectModeMask;
}

-(NSView*)initialKeyView
{
	return self.wsheetFontField;
}

-(NSString*)identifier
{
	return @"FontPrefs";
}

-(NSImage*)toolbarItemImage
{
	return [NSImage imageNamed:NSImageNameFontPanel];
}

-(NSString*)toolbarItemLabel
{
	return @"Fonts";
}

-(IBAction)setColor:(NSColor*)color forAttribute:(NSString*)attr
{
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	if ([attr isEqualToString:NSForegroundColorAttributeName]) {
		[prefs setObject:[color hexString] forKey:kPref_EditorFontColor];
		[self.wsheetFontField setTextColor:color];
	} else if ([attr isEqualToString:@"NSDocumentBackgroundColor"]) {
		[prefs setObject:[color hexString] forKey:kPref_EditorBGColor];
		[self.wsheetFontField setBackgroundColor:color];
	}
}

-(IBAction)changeWorksheetFont:(id)sender
{
	NSFontManager *fm = [NSFontManager sharedFontManager];
	[fm setSelectedFont:self.wsheetFont isMultiple:NO];
	[fm orderFrontFontPanel:self];
	[[NSFontManager sharedFontManager] setAction:@selector(changeEditorFont:)];
	[[NSFontManager sharedFontManager] setTarget:self];
	[self.view.window makeFirstResponder:self.wsheetFontField];
}

-(IBAction)changeEditorFont:(id)sender
{
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	self.wsheetFont = [sender convertFont:self.wsheetFont];
	self.wsheetFontField.font = self.wsheetFont;
	self.wsheetFontDescription = [NSString stringWithFormat:@"%@ %1.1f",
								self.wsheetFont.fontName, self.wsheetFont.pointSize];
	[prefs setObject:self.wsheetFont.fontName forKey:kPref_EditorFont];
	[prefs setFloat:self.wsheetFont.pointSize forKey:kPref_EditorFontSize];
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
	[[NSFontManager sharedFontManager] setDelegate:self];
	[[self.view.window fieldEditor:YES forObject:control] setUsesFontPanel:YES];
	return NO;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	[[NSFontManager sharedFontManager] setDelegate:nil];
	return YES;
}

@synthesize wsheetFontField;
@synthesize wsheetFont;
@synthesize wsheetFontDescription;
@end
