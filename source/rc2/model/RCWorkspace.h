//
//  RCWorkspace.h
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCWorkspaceItem.h"

@class RCFile;
@class RCWorkspaceShare;
@class RCWorkspaceCache;

@interface RCWorkspace : RCWorkspaceItem
@property (nonatomic, copy, readonly) NSArray *files;
@property (nonatomic, strong) NSMutableArray *shares;
@property (nonatomic, readonly) BOOL sharedByOther;
@property (nonatomic, readonly) RCWorkspaceCache *cache;
@property (nonatomic) BOOL updateFileContentsOnNextFetch; //if set to YES, will async grab contents of any empty or modified files

-(void)refreshFiles;
-(void)refreshFilesPerformingBlockBeforeNotification:(BasicBlock)block;
-(void)refreshShares;

-(void)addFile:(RCFile*)aFile;
-(RCFile*)fileWithId:(NSNumber*)fileId;
-(RCFile*)fileWithName:(NSString*)fileName;

//for others to tell the workspace that a file was added or updated
-(void)updateFileId:(NSNumber*)fileId;

-(RCWorkspaceShare*)shareForUserId:(NSNumber*)userId;

//for workspaceshares to be updated
-(void)updateShare:(RCWorkspaceShare*)share permission:(NSString*)perm;
@end

//notification posted when a workspace has (re)fetched its file contents
// this is so the app can cache all files w/o observing every workspace
extern NSString * const RCWorkspaceFilesFetchedNotification;