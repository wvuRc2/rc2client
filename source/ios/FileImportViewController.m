//
//  FileImportViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 1/9/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "Vyana-ios/AMNavigationTreeController.h"
#import "FileImportViewController.h"
#import "Rc2Server.h"
#import "RCProject.h"
#import "RCWorkspace.h"
#import "MAKVONotificationCenter.h"

@interface FileImportViewController () <AMNavigationTreeDelegate>
@property (nonatomic, strong) AMNavigationTreeController *treeController;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UILabel *importLabel;
@property (weak, nonatomic) IBOutlet UIView *treeContainer;
@property (nonatomic, copy) NSArray *projects;
@end

@implementation FileImportViewController

-(id)init
{
	if ((self = [super initWithNibName:@"FileImportViewController" bundle:nil])) {
		self.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doDone:)];
	self.navigationItem.rightBarButtonItem = doneButton;
	self.navigationItem.title = @"Import File";
	NSMutableArray *prjs = [[Rc2Server sharedInstance].projects mutableCopy];
	for (NSInteger i=prjs.count-1; i>=0; i--) {
		if (![[prjs objectAtIndex:i] userEditable])
			[prjs removeObjectAtIndex:i];
	}
	self.projects = prjs;
	self.treeController = [[AMNavigationTreeController alloc] init];
	[self addChildViewController:self.treeController];
	self.treeController.delegate = self;
	self.treeController.keyForCellText = @"name";
	self.treeController.navigationItem.rightBarButtonItem = doneButton;
	[self.treeContainer addSubview:self.treeController.view];
	self.treeController.view.frame = self.treeContainer.bounds;
	self.importLabel.text = [NSString stringWithFormat:@"Import \"%@\" to:", self.inputUrl.lastPathComponent];
	[self observeTarget:self.treeController keyPath:@"selectedItem" options:0 block:^(MAKVONotification *note) {
		[note.observer selectionChanged];
	}];
}

#pragma mark - meat & potatos

-(void)selectionChanged
{
	id selItem = self.treeController.selectedItem;
	if ([selItem isKindOfClass:[RCWorkspace class]]) {
		[self dismissSelf];
		//we do the actual import
		Rc2LogVerbose(@"imported %@ to %@", self.inputUrl.lastPathComponent, [selItem name]);
	}
}

-(void)dismissSelf
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		if (self.cleanupBlock)
			self.cleanupBlock();
	}];
}

#pragma mark - nav tree

-(NSInteger)navTree:(AMNavigationTreeController*)navTree numberOfChildrenOfItem:(id)item
{
	if (nil == item)
		return self.projects.count;
	if ([item isKindOfClass:[RCProject class]])
		return [[item workspaces] count];
	if ([item isKindOfClass:[RCWorkspace class]])
		return [[item files] count];
	Rc2LogWarn(@"returning a default child count which should never happen");
	return 0;
}

-(id)navTree:(AMNavigationTreeController*)navTree childOfItem:(id)item atIndex:(NSInteger)index
{
	id rs=nil;
	if (nil == item)
		rs = [self.projects objectAtIndex:index];
	else if ([item isKindOfClass:[RCProject class]])
		rs = [[item workspaces] objectAtIndex:index];
	return rs;
}

-(BOOL)navTree:(AMNavigationTreeController*)navTree isLeafItem:(id)item
{
	return ![item isKindOfClass:[RCProject class]];
}

#pragma mark - actions

-(IBAction)doDone:(id)sender
{
	[self dismissSelf];
}

@end
