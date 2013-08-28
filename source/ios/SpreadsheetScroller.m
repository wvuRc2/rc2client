//
//  SpreadsheetScroller.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/22/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "SpreadsheetScroller.h"
#import "SpreadsheetCell.h"

@interface SpreadsheetScroller ()
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) NSMutableSet *cachedCells;
@property NSInteger firstVisibleRow;
@property NSInteger lastVisibleRow;
@property NSInteger firstVisibleCol;
@property NSInteger lastVisibleCol;
@end

@implementation SpreadsheetScroller {
	BOOL _didSetup;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	self.showRowHeaders = YES;
	self.cachedCells = [NSMutableSet set];
	//let's throw a bunch in there
	for (int i=0; i < 20; i++)
		[self.cachedCells addObject:[[SpreadsheetCell alloc] initWithFrame:CGRectZero]];
	_containerView = [[UIView alloc] initWithFrame:self.bounds];
	_containerView.layer.masksToBounds = YES;
	[self addSubview:_containerView];
	_containerView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
	self.scrollEnabled=YES;
	self.delegate = self;
	_firstVisibleRow = _firstVisibleCol = NSIntegerMax;
	_lastVisibleRow = _lastVisibleCol = NSIntegerMin;
	[[NSNotificationCenter defaultCenter] addObserverForName:UIContentSizeCategoryDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note)
	 {
		 for (SpreadsheetCell *cell in _containerView.subviews)
		 {
			 [cell updateFont];
		 }
	 }];

}

-(void)initialSetup
{
	CGSize sz = self.bounds.size;
	CGSize tileSize = _dataSource.ssheetCellSize;
	CGFloat docWidth = (_dataSource.ssheetColumnCount + (_showRowHeaders ? 1 : 0)) * tileSize.width;
	CGFloat docHeight = _dataSource.ssheetRowCount * tileSize.height;
	sz.width = MAX(docWidth, self.bounds.size.width);
	sz.height = MAX(docHeight, self.bounds.size.height);
	self.contentSize = sz;
	[_containerView setFrame:CGRectMake(0, 0, sz.width, sz.height)];
	if (self.headerView) {
		sz.height = tileSize.height;
		self.headerView.contentSize = sz;
		if (self.headerView.frame.size.height > sz.height) {
			CGRect fr = self.headerView.frame;
			fr.size.height = tileSize.height;
			self.headerView.frame = fr;
		}
		UIView *hcontainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, sz.width, sz.height)];
		hcontainer.backgroundColor = [UIColor clearColor];
		[self.headerView addSubview:hcontainer];
		hcontainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self populateHeaderView:hcontainer];
	}
}

-(void)layoutSubviews
{
	[super layoutSubviews];
	if (!_didSetup) {
		[self initialSetup];
		_didSetup = YES;
	}
	
	CGRect visibleBounds = self.bounds;
	
	//recycle tiles that are no longer visible
	for (SpreadsheetCell *aCell in [_containerView.subviews copy]) {
		CGRect frame = [_containerView convertRect:aCell.frame toView:self];
		if (! CGRectIntersectsRect(frame, visibleBounds))
			[self recycleCell:aCell];
	}
	
	CGSize tileSize = self.dataSource.ssheetCellSize;
	CGFloat cwidth = tileSize.width;
	CGFloat cheight = tileSize.height;
	int maxRow = MIN(floorf(_containerView.frame.size.height / cheight), self.dataSource.ssheetRowCount);
	int maxCol = MIN(floorf(_containerView.frame.size.width / cwidth), self.dataSource.ssheetColumnCount + (_showRowHeaders ? 1 : 0));
	int firstNeededRow = MAX(0, floorf(visibleBounds.origin.y / cheight));
	int firstNeededCol = MAX(0, floorf(visibleBounds.origin.x / cwidth));
	int lastNeededRow = MIN(maxRow-1, floorf(CGRectGetMaxY(visibleBounds) / cheight));
	int lastNeededCol = MIN(maxCol-1, floorf(CGRectGetMaxX(visibleBounds) / cwidth));
	
	for (int row=firstNeededRow; row <= lastNeededRow; row++) {
		for (int col=firstNeededCol; col <= lastNeededCol; col++) {
			BOOL tileIsMissing = (_firstVisibleRow > row || _firstVisibleCol > col ||
								  _lastVisibleCol < col || _lastVisibleRow < row);
			if (tileIsMissing) {
				SpreadsheetCell *cell = [self dequeueCell];
				if (_showRowHeaders && col == 0) {
					cell.content = [self.dataSource ssheetContentForRow:row column:-1];
					cell.isHeader = YES;
				} else {
					cell.content = [self.dataSource ssheetContentForRow:row column:col + (_showRowHeaders ? -1 : 0)];
					cell.isHeader = NO;
				}
				[cell setNeedsDisplay];
				cell.frame = CGRectMake(cwidth * col, cheight * row, cwidth, cheight);
				[_containerView addSubview:cell];
			}
		}
	}
	_firstVisibleRow = firstNeededRow; _firstVisibleCol = firstNeededCol;
	_lastVisibleRow = lastNeededRow; _lastVisibleCol = lastNeededCol;
}

-(SpreadsheetCell*)dequeueCell
{
	SpreadsheetCell *tview = [self.cachedCells anyObject];
	if (nil == tview)
		tview = [[SpreadsheetCell alloc] initWithFrame:CGRectZero];
	else
		[self.cachedCells removeObject:tview];
	return tview;
}

-(void)recycleCell:(SpreadsheetCell*)cell
{
	[cell removeFromSuperview];
	cell.isHeader = NO;
	[_cachedCells addObject:cell];
}

-(void)populateHeaderView:(UIView*)hview
{
	CGSize tileSize = self.dataSource.ssheetCellSize;
	CGRect frame = CGRectMake(0, 0, tileSize.width, tileSize.height);
	if (_showRowHeaders) {
		SpreadsheetCell *cell = [[SpreadsheetCell alloc] initWithFrame:frame];
		cell.isHeader = YES;
		[hview addSubview:cell];
		frame.origin.x += tileSize.width;
	}
	for (int col=0; col < self.dataSource.ssheetColumnCount; col++) {
		SpreadsheetCell *tile = [[SpreadsheetCell alloc] initWithFrame:frame];
		tile.content = [[self.dataSource ssheetColumnTitles] objectAtIndex:col];
		tile.isHeader = YES;
		[hview addSubview:tile];
		frame.origin.x += tileSize.width;
	}
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (scrollView == self) {
		CGPoint offset = self.contentOffset;
		CGPoint headOffset = CGPointMake(offset.x, 0);
		[self.headerView setContentOffset:headOffset animated:NO];
	}
}


@end
