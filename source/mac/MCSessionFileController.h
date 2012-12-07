//
//  MCSessionFileController.h
//  Rc2Client
//
//  Created by Mark Lilback on 12/4/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCSession;
@class RCFile;
@protocol MCSessionFileControllerDelegate;

@interface MCSessionFileController : NSObject<NSTableViewDataSource,NSTableViewDelegate,NSMenuDelegate>
@property (nonatomic, weak) id<MCSessionFileControllerDelegate> delegate;
@property (nonatomic, strong) RCSession *session;
@property (nonatomic, strong) NSTableView *fileTableView;
@property (nonatomic, strong) RCFile *selectedFile;
@property (nonatomic, strong) NSNumber *fileIdJustImported;

-(id)initWithSession:(RCSession*)aSession tableView:(NSTableView*)tableView delegate:(id<MCSessionFileControllerDelegate>)aDelegate;

-(void)updateFileArray;

@end

@protocol MCSessionFileControllerDelegate <NSObject>

-(void)syncFile:(RCFile*)file;
-(void)fileSelectionChanged:(RCFile*)selectedFile oldSelection:(RCFile*)oldFile;

@end

@interface MCSessionFileTableView : NSTableView
@end