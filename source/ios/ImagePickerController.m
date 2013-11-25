//
//  ImagePickerController.m
//  Rc2Client
//
//  Created by Mark Lilback on 5/7/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "ImagePickerController.h"
#import "RCImage.h"

@interface ImagePickerController ()
@end

@interface ImagePickerCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *label;
@property (nonatomic, weak) NSLayoutConstraint *hwConstraint;
@end

@implementation ImagePickerController

- (id)init
{
	self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	//self.clearsSelectionOnViewWillAppear = NO;
	[self.tableView registerNib:[UINib nibWithNibName:@"ImagePickerCell" bundle:nil] forCellReuseIdentifier:@"image"];
	self.tableView.rowHeight = 120;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.images.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//	static NSString *CellIdentifier = @"Cell";
	ImagePickerCell *cell = (ImagePickerCell*)[tableView dequeueReusableCellWithIdentifier:@"image"];
	RCImage *img = [self.images objectAtIndex:indexPath.row];
	cell.label.text = img.name;
	cell.imageView.image = img.image;
	if (img == self.selectedImage) {
		//select it
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.selectedImage = [self.images objectAtIndexNoExceptions:indexPath.row];
	if (self.selectionHandler)
		self.selectionHandler();
}

@end

@implementation ImagePickerCell
-(void)prepareForReuse
{
	[self setNeedsUpdateConstraints];
	[super prepareForReuse];
}
-(void)updateConstraints
{
	if (nil == self.hwConstraint) {
		NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.imageView attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
		self.hwConstraint = c;
		[self.contentView addConstraint:c];
	}
	[super updateConstraints];
}
@end
