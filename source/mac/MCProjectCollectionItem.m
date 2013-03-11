//
//  MCProjectCollectionItem.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/25/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "MCProjectCollectionItem.h"
#import "MCProjectCollectionView.h"
#import "RCProject.h"
#import "RCWorkspace.h"
#import "ThemeEngine.h"

@interface MacProjectCellView : AMControlledView
@property (nonatomic) BOOL selected;
@property (nonatomic) BOOL isProject;
@property (strong) AMColor *regColor;
@property (weak) CALayer *innerLayer;
@property (weak) IBOutlet NSTextField *itemLabel;
@property (nonatomic, weak) IBOutlet NSView *innerView;
-(void)startEditing;
-(void)endEditing;
@end

@interface MCProjectCollectionItem()
@property BOOL canEdit;
@end

@implementation MCProjectCollectionItem

-(void)dealloc
{
	if ([self.view isKindOfClass:[AMControlledView class]])
		[(AMControlledView*)self.view setViewController:nil];
}

-(void)controlTextDidEndEditing:(NSNotification *)obj
{
	[self.cellView endEditing];
	NSString *oldVal = [self.representedObject name];
	NSString *newVal = self.itemLabel.stringValue;
	if (![newVal isEqualToString:oldVal]) {
		id del = [self.collectionView delegate];
		if ([del respondsToSelector:@selector(collectionView:renameItem:name:)]) {
			[del collectionView:(id)self.collectionView renameItem:self name:newVal];
		}
	}
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector;
{
	BOOL result = NO;
	if (commandSelector == @selector(cancelOperation:)) {
		[self.itemLabel abortEditing];
		[self.cellView endEditing];
		self.itemLabel.stringValue = [self.representedObject name];
		result = YES;
	} else if (commandSelector == @selector(insertNewline:)) {
		[self.cellView endEditing];
		[self.cellView.window makeFirstResponder:nil];
		result = YES;
	} else {
		NSLog(@"call %@", NSStringFromSelector(commandSelector));
	}
	return result;
}

-(void)startNameEditing
{
	if (self.canEdit)
		[self.cellView startEditing];
}

-(MacProjectCellView*)cellView
{
	return (MacProjectCellView*)self.view;
}

-(void)reloadItemDetails
{
	if ([self.representedObject isKindOfClass:[RCProject class]]) {
		RCProject *proj = self.representedObject;
		self.canEdit = proj.userEditable;
		if ([proj.type isEqualToString:@"shared"])
			self.imageView.image = [NSImage imageNamed:NSImageNameDotMac];
		else if ([proj.type isEqualToString:@"admin"])
			self.imageView.image = [NSImage imageNamed:NSImageNameUserAccounts];
		else
			self.imageView.image = [NSImage imageNamed:NSImageNameFolder];
	} else {
		//workspace
		self.imageView.image = [NSImage imageNamed:NSImageNameMultipleDocuments];
	}
	NSString *label = [self.representedObject name];
	if (nil == label)
		label = @"";
	self.itemLabel.stringValue = label;
}

-(void)setRepresentedObject:(id)representedObject
{
	[super setRepresentedObject:representedObject];
	if (nil == self.itemLabel) {
		NSString *nibName = [representedObject isKindOfClass:[RCProject class]] ? @"MCProjectCollectionItem" : @"MCProjectItemWorkspace";
		ZAssert([[NSBundle mainBundle] loadNibNamed:nibName owner:self topLevelObjects:nil], @"failed to load nib");
		[(AMControlledView*)self.view setViewController:self];
	}
	self.itemLabel.delegate = self;
	[self.cellView setItemLabel:self.itemLabel];
	self.cellView.isProject = [representedObject isKindOfClass:[RCProject class]];
	[self reloadItemDetails];
}

-(void)setSelected:(BOOL)selected
{
	[super setSelected:selected];
	[(MacProjectCellView*)self.view setSelected:selected];
}

@end

@implementation MacProjectCellView

-(void)awakeFromNib
{
	self.isProject = YES;
	CALayer *layer = self.innerView.layer;
	layer.cornerRadius = 13.0;
	layer.backgroundColor = [NSColor whiteColor].CGColor;

	layer = [CALayer layer];
	layer.frame = self.innerView.frame;
	layer.shadowColor = [[NSColor blackColor] colorWithAlphaComponent:0.5].CGColor;
	layer.shadowOpacity = 0.8;
	layer.shadowOffset = CGSizeMake(2, -2);
	layer.shadowRadius = 2;
	layer.cornerRadius = 13.0;
	layer.backgroundColor = self.regColor.CGColor;
	[self.layer addSublayer:layer];
	self.innerLayer = layer;
	
	self.layer.backgroundColor = [NSColor clearColor].CGColor;

	__weak MacProjectCellView *bself = self;
	[[ThemeEngine sharedInstance] registerThemeChangeBlock:^(Theme *theme) {
		[bself adjustColors];
	}];
}

-(void)startEditing
{
	MCProjectCollectionItem *citem = (MCProjectCollectionItem*)self.viewController;
	if (![citem.representedObject userEditable])
		return;
	//start editing the name
	[self.itemLabel setEditable:YES];
	[self.window makeFirstResponder:self.itemLabel];
	NSCollectionView *colView = [(MCProjectCollectionItem*)self.viewController collectionView];
	[colView setSelectionIndexes:nil];
}

-(void)endEditing
{
	[self.itemLabel setEditable:NO];
}

-(NSView*)hitTest:(NSPoint)aPoint
{
	NSRect f = [self.superview convertRect:self.itemLabel.frame fromView:self.itemLabel.superview];
	if (NSPointInRect(aPoint, f) && nil == self.itemLabel.currentEditor) {
		[self startEditing];
		return nil;
	}
	if (NSPointInRect(aPoint, [self convertRect:self.bounds toView:self.superview]))
		return self;
	return nil;
}

-(void)mouseDown:(NSEvent *)theEvent
{
	if (2 == theEvent.clickCount) {
	} else {
		[super mouseDown:theEvent];
	}
}

-(void)mouseUp:(NSEvent *)theEvent
{
	if (2 == theEvent.clickCount && nil == self.itemLabel.currentEditor) {
		id colView = [(MCProjectCollectionItem*)self.viewController collectionView];
		id del = [colView delegate];
		if ([del respondsToSelector:@selector(collectionView:doubleClicked:item:)]) {
			[del collectionView:colView doubleClicked:theEvent item:self.viewController.representedObject];
		}
	}
}

-(void)adjustColors
{
	Theme *theme = [[ThemeEngine sharedInstance] currentTheme];
	AMColor *color = [AMColor colorWithColor: [theme colorForKey: self.isProject ? @"ProjectColor" : @"WorkspaceColor"]];
	self.regColor = [color colorWithAlpha:0.3];
	self.innerLayer.backgroundColor = self.regColor.CGColor;
}

-(void)setIsProject:(BOOL)isProject
{
	Theme *theme = [[ThemeEngine sharedInstance] currentTheme];
	_isProject = isProject;
	AMColor *color = [AMColor colorWithColor: [theme colorForKey: isProject ? @"ProjectColor" : @"WorkspaceColor"]];
	self.regColor = [color colorWithAlpha:0.3];
	self.innerLayer.backgroundColor = self.regColor.CGColor;
}

-(void)setSelected:(BOOL)selected
{
	_selected = selected;
	if (selected)
		self.layer.backgroundColor = [NSColor selectedControlColor].CGColor;
	else
		self.layer.backgroundColor = [NSColor whiteColor].CGColor;
	[self.layer setNeedsDisplay];
}


@end