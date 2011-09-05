//
//  MessageListCell.h
//  iPadClient
//
//  Created by Mark Lilback on 9/4/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCMessage;

@interface BodyDrawingView : UIView
@property (nonatomic, copy) NSString *bodyText;
@end

@interface MessageListCell : iAMTableViewCell
@property (nonatomic, assign) IBOutlet UILabel *subjectLabel;
@property (nonatomic, assign) IBOutlet UILabel *fromLabel;
@property (nonatomic, assign) IBOutlet UILabel *dateLabel;
@property (nonatomic, assign) IBOutlet UIImageView *priorityFlag;
@property (nonatomic, assign) IBOutlet BodyDrawingView *bodyView;
@property (nonatomic, assign) IBOutlet UIView *view;
@property (nonatomic, assign) IBOutlet UIButton *deleteButton;

@property (nonatomic, retain) NSArray *priorityImages;


//returns extra height needed to fit the body string in the cell (if selected)
-(CGFloat)setMessage:(RCMessage*)message selected:(BOOL)selected;

-(CGFloat)calculateHeightWithBody:(NSString*)body;
-(CGFloat)defaultCellHeight;

@end
