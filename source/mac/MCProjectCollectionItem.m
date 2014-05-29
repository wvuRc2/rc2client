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
#import "Rc2Server.h"

@interface MacProjectCellView : AMControlledView
@property (nonatomic) BOOL selected;
@property (nonatomic, weak) id representedObject;
@property (nonatomic, readonly) RCProject *project;
@property (nonatomic, readonly) RCWorkspace *workspace;
//legacy accessors from before we had above
@property (nonatomic, readonly) BOOL isProject;
@property (nonatomic, readonly) BOOL isClass;

@property (strong) AMColor *regColor;
@property (weak) CALayer *innerLayer;
@property (weak) IBOutlet NSTextField *itemLabel;
@property (nonatomic, weak) IBOutlet NSView *innerView;
@property (nonatomic, weak) IBOutlet NSButton *shareButton;
-(void)startEditing;
-(void)endEditing;
-(void)adjustColors;
-(void)setupShareButton;
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

-(void)adjustShareButton
{
	RCWorkspace *ws = self.representedObject;
	if (ws.isShareNone) {
		self.cellView.shareButton.image = [NSImage imageNamed:@"sharedDisabled"];
		self.cellView.shareButton.toolTip = @"Not shared";
	} else if (ws.isShareRO) {
			self.cellView.shareButton.image = [NSImage imageNamed:@"shared"];
			self.cellView.shareButton.toolTip = @"Shared read-only";
	} else if (ws.isShareRW) {
		self.cellView.shareButton.image = [NSImage imageNamed:@"sharedFull"];
		self.cellView.shareButton.toolTip = @"Shared read-write";
	}
}

-(IBAction)shareButtonClicked:(id)sender
{
	if ([self.representedObject isKindOfClass:[RCProject class]]) {
		//tell delegate
		id del = self.collectionView.delegate;
		NSRect r = [self.cellView.shareButton convertRect:self.cellView.shareButton.bounds toView:self.collectionView];
		[del collectionView:(id)self.collectionView showShareInfo:self.representedObject fromRect:r];
	} else {
		//workspace
		RCWorkspace *ws = self.representedObject;
		NSString *newPerm = nil;
		if (ws.isShareNone)
			newPerm = @"ro";
		else if (ws.isShareRO)
			newPerm = @"rw";
		[[Rc2Server sharedInstance] updateWorkspaceShare:ws perm:newPerm completionHandler:^(BOOL success, id results)
		{
			[self adjustShareButton];
			if (!success) {
				NSBeep();
				//TODO: give message to user
			}
		}];
	}
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
		[self.lastModifiedField setStringValue:@""];
		[[self.cellView shareButton] setHidden: !proj.userEditable];
	} else {
		//workspace
		RCWorkspace *ws = self.representedObject;
		self.imageView.image = [NSImage imageNamed:NSImageNameMultipleDocuments];
		[self.lastModifiedField setObjectValue:ws.lastAccess];
		[[self.cellView shareButton] setHidden:ws.project.isShared];
		[self adjustShareButton];
	}
	NSString *label = [self.representedObject name];
	if (nil == label)
		label = @"";
	self.itemLabel.stringValue = label;
}

-(void)setRepresentedObject:(id)representedObject
{
	[super setRepresentedObject:representedObject];
	if (representedObject) {
		NSString *nibName = [representedObject isKindOfClass:[RCProject class]] ? @"MCProjectCollectionItem" : @"MCProjectItemWorkspace";
		ZAssert([[NSBundle mainBundle] loadNibNamed:nibName owner:self topLevelObjects:nil], @"failed to load nib");
		[(AMControlledView*)self.view setViewController:self];
	}
	self.itemLabel.delegate = self;
	[self.cellView setItemLabel:self.itemLabel];
	self.cellView.representedObject = self.representedObject;
	[self.cellView adjustColors];
	[self.cellView setupShareButton];
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

-(RCProject*)project
{
	if ([self.representedObject isKindOfClass:[RCProject class]])
		return self.representedObject;
	return nil;
}

-(RCWorkspace*)workspace
{
	if ([self.representedObject isKindOfClass:[RCWorkspace class]])
		return self.representedObject;
	return nil;
}

-(BOOL)isClass { return self.project.isClass; }

-(BOOL)isProject { return [self.representedObject isKindOfClass:[RCProject class]]; }

-(void)setupShareButton
{
	if (self.project) {
		NSImage *baseImg = [NSImage imageNamed:@"shareperm"];
		self.shareButton.image = [baseImg tintedImageWithColor:[NSColor darkGrayColor]];
		self.shareButton.alternateImage = [baseImg tintedImageWithColor:[NSColor lightGrayColor]];
	} else {
		self.shareButton.image = [NSImage imageNamed:@"shared"];
		self.shareButton.alternateImage = [NSImage imageNamed:@"sharedFull"];
	}
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
	
	f = [self.superview convertRect:self.shareButton.frame fromView:self.shareButton.superview];
	if (NSPointInRect(aPoint, f) && !self.shareButton.isHidden) {
		return self.shareButton;
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
	if (self.project) {
		if (self.project.isClass)
			cstring = @"ClassColor";
		else if (self.project.isShared)
			cstring = @"SharedProjectColor";
		else
			cstring = @"ProjectColor";
	}
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