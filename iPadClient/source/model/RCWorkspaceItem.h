//
//  RC2WorkspaceItem.h
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCWorkspaceItem : NSObject {}

//instantiates the correct subclass
+(id)workspaceItemWithDictionary:(NSDictionary*)dict;

-(id)initWithDictionary:(NSDictionary*)dict;

@property (nonatomic, retain) NSNumber *wspaceId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) NSNumber *parentId;
@property (nonatomic, readonly) BOOL isFolder;

-(NSComparisonResult)compareWithItem:(RCWorkspaceItem*)anItem;
@end
