//
//  SpreadsheetScroller.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/22/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SpreadsheetDataSource;

//must be delegate to self
@interface SpreadsheetScroller : UIScrollView<UIScrollViewDelegate>
@property (nonatomic, weak) IBOutlet UIScrollView *headerView;
@property (nonatomic, weak) id<SpreadsheetDataSource> dataSource;
@end

@protocol SpreadsheetDataSource <NSObject>
-(CGSize)ssheetCellSize; //should not change
-(NSArray*)ssheetColumnTitles;
-(NSInteger)ssheetRowCount;
-(NSInteger)ssheetColumnCount;
-(NSString*)ssheetContentForRow:(NSInteger)row column:(NSInteger)col;
@end

