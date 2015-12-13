//
//  MCProjectCollectionItem.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/25/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "MCProjectCollectionItem.h"
#import "MCProjectCollectionView.h"
#import "Rc2-Swift.h"
#import "ThemeEngine.h"

@interface MacProjectCellView : AMControlledView
@property (nonatomic) BOOL selected;
@property (nonatomic, weak) id representedObject;
@property (nonatomic, readonly) Rc2Workspace *workspace;

@property (strong) AMColor *regColor;
@property (weak) CALayer *innerLayer;
@property (weak) IBOutlet NSTextField *itemLabel;
@property (nonatomic, weak) IBOutlet NSView *innerView;
-(void)startEditing;
-(void)endEditing;
-(void)adjustColors;
@end

@interface MCProjectCollectionItem()
@property (weak) IBOutlet NSTextField *lastModifiedField;
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
		Rc2LogVerbose(@"call %@", NSStringFromSelector(commandSelector));
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
	//workspace
	Rc2Workspace *ws = self.representedObject;
	self.imageView.image = [NSImage imageNamed:NSImageNameMultipleDocuments];
	NSString *label = [self.representedObject name];
	if (nil == label)
		label = @"";
	self.itemLabel.stringValue = label;
}

-(void)setRepresentedObject:(id)representedObject
{
	[super setRepresentedObject:representedObject];
	if (representedObject) {
		ZAssert([[NSBundle mainBundle] loadNibNamed:@"MCProjectItemWorkspace" owner:self topLevelObjects:nil], @"failed to load nib");
		[(AMControlledView*)self.view setViewController:self];
	}
	self.itemLabel.delegate = self;
	[self.cellView setItemLabel:self.itemLabel];
	self.cellView.representedObject = self.representedObject;
	[self.cellView adjustColors];
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
	[[ThemeEngine sharedInstance] registerThemeChangeObserver:self block:^(Theme *theme) {
		[bself adjustColors];
	}];
}

-(void)startEditing
{
	MCProjectCollectionItem *citem = (MCProjectCollectionItem*)self.viewController;
	//start editing the name
	[self.itemLabel setEditable:YES];
	[self.window makeFirstResponder:self.itemLabel];
	NSCollectionView *colView = [(MCProjectCollectionItem*)self.viewController collectionView];
	[colView setSelectionIndexes:[NSIndexSet indexSet]];
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
	NSString *cstring = @"WorkspaceColor";
	AMColor *color = [AMColor colorWithColor: [theme colorForKey: cstring]];
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