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
	//stick ourselves in the responder chain
	[self setNextResponder: [self.view nextResponder]];
	[self.view setNextResponder: self];
	id fontName = [_prefs objectForKey:kPref_EditorFont];
	if (![fontName isKindOfClass:[NSString class]])
		fontName = @"Menlo";
	CGFloat fntSize = [_prefs floatForKey:kPref_EditorFontSize];
	if ((fntSize < 9) || (fntSize > 72))
		fntSize = 13.0;
	self.wsheetFont = [NSFont fontWithName:fontName size:fntSize];
	self.wsheetFontField.font = self.wsheetFont;
	self.wsheetFontField.backgroundColor = [NSColor colorWithHexString:[_prefs objectForKey:kPref_EditorBGColor]];
	self.wsheetFontField.textColor = [NSColor colorWithHexString:[_prefs objectForKey:kPref_EditorFontColor]];
	self.wsheetFontDescription = [NSString stringWithFormat:@"%@ %1.1f",
								self.wsheetFont.fontName, self.wsheetFont.pointSize];
}

- (NSUInteger)validModesForFontPanel:(NSFontPanel *)fontPanel
{
	return NSFontPanelFaceModeMask|NSFontPanelSizeModeMask|NSFontPanelCollectionModeMask|NSFontPanelTextColorEffectModeMask|NSFontPanelDocumentColorEffectModeMask;
}

-(IBAction)setColor:(NSColor*)color forAttribute:(NSString*)attr
{
	if ([attr isEqualToString:NSForegroundColorAttributeName]) {
		[_prefs setObject:[color hexString] forKey:kPref_EditorFontColor];
		[self.wsheetFontField setTextColor:color];
	} else if ([attr isEqualToString:@"NSDocumentBackgroundColor"]) {
		[_prefs setObject:[color hexString] forKey:kPref_EditorBGColor];
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
	NSLog(@"chain:%@", self.view.window.responderChainDescription);
	[self.view.window makeFirstResponder:self.wsheetFontField];
}

-(IBAction)changeEditorFont:(id)sender
{
	self.wsheetFont = [sender convertFont:self.wsheetFont];
	self.wsheetFontField.font = self.wsheetFont;
	self.wsheetFontDescription = [NSString stringWithFormat:@"%@ %1.1f",
								self.wsheetFont.fontName, self.wsheetFont.pointSize];
	[_prefs setObject:self.wsheetFont.fontName forKey:kPref_EditorFont];
	[_prefs setFloat:self.wsheetFont.pointSize forKey:kPref_EditorFontSize];
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
