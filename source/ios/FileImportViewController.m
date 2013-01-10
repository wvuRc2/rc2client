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

@interface FileImportViewController () <AMNavigationTreeDelegate>
@property (nonatomic, strong) AMNavigationTreeController *navController;
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
	self.navigationItem.title = @"Import do-hickey";
	NSMutableArray *prjs = [[Rc2Server sharedInstance].projects mutableCopy];
	for (NSInteger i=prjs.count-1; i>=0; i--) {
		if (![[prjs objectAtIndex:i] userEditable])
			[prjs removeObjectAtIndex:i];
	}
	self.projects = prjs;
	self.navController = [[AMNavigationTreeController alloc] init];
	self.navController.manageNavigationStack = NO;
	self.navController.delegate = self;
	self.navController.keyForCellText = @"name";
	[self.treeContainer addSubview:self.navController.view];
	self.navController.view.frame = self.treeContainer.bounds;
	self.importLabel.text = [NSString stringWithFormat:@"Import \"%@\" to:", self.inputUrl.lastPathComponent];
}

-(NSInteger)navTree:(AMNavigationTreeController*)navTree numberOfChildrenOfItem:(id)item
{
	if (nil == item)
		return self.projects.count;
	if ([item conformsToProtocol:@protocol(RCFileContainer)])
		return [[item files] count];
	return 0;
}

-(id)navTree:(AMNavigationTreeController*)navTree childOfItem:(id)item atIndex:(NSInteger)index
{
	if (nil == item)
		return [self.projects objectAtIndex:index];
	if ([item isKindOfClass:[RCProject class]])
		return [[item workspaces] objectAtIndex:index];
	return nil;
}

-(void)navTree:(AMNavigationTreeController *)navTree willDisplayCell:(UITableViewCell *)cell forItem:(id)item
{
	NSLog(@"showing cell with check:%d", cell.accessoryType);
}

-(BOOL)navTree:(AMNavigationTreeController*)navTree isLeafItem:(id)item
{
	return ![item isKindOfClass:[RCProject class]];
}

-(IBAction)doCancel:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		if (self.cleanupBlock)
			self.cleanupBlock();
	}];
}

-(IBAction)doImport:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		if (self.cleanupBlock)
			self.cleanupBlock();
	}];
}

@end
