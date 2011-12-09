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
@property (nonatomic, strong) IBOutlet UILabel *subjectLabel;
@property (nonatomic, strong) IBOutlet UILabel *fromLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UIImageView *priorityFlag;
@property (nonatomic, strong) IBOutlet BodyDrawingView *bodyView;
@property (nonatomic, strong) IBOutlet UIView *view;
@property (nonatomic, strong) IBOutlet UIButton *deleteButton;

@property (nonatomic, strong) NSArray *priorityImages;


//returns extra height needed to fit the body string in the cell (if selected)
-(CGFloat)setMessage:(RCMessage*)message selected:(BOOL)selected;
-(void)setIsSelected:(BOOL)selected;

-(CGFloat)calculateHeightWithBody:(NSString*)body;
-(CGFloat)defaultCellHeight;

@end
