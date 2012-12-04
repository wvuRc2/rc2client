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
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (nil == cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
	RCImage *img = [self.images objectAtIndex:indexPath.row];
	cell.textLabel.text = img.name;
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
