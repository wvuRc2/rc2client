//
//  RC2WorkspaceItem.h
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCWorkspaceItem : NSObject {}

//instantiates the correct subclass
+(id)workspaceItemWithDictionary:(NSDictionary*)dict;

-(id)initWithDictionary:(NSDictionary*)dict;

@property (nonatomic, weak) RCWorkspaceItem *parentItem;
@property (nonatomic, strong) NSNumber *wspaceId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSNumber *parentId;
@property (nonatomic, readonly) BOOL isFolder;
@property (nonatomic, readonly) BOOL canDelete;
@property (nonatomic, readonly) BOOL canRename;

-(NSComparisonResult)compareWithItem:(RCWorkspaceItem*)anItem;
@end
