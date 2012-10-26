//
//  RCProject.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/25/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCProject : NSObject

@property (nonatomic, strong) NSNumber *projectId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, strong, readonly) NSArray *workspaces;
@property (nonatomic, strong, readonly) NSArray *subprojects;
@property (nonatomic, weak) RCProject *parentProject;
@property (readonly) NSInteger childCount; //workspaces + subprojects

+(NSArray*)projectsForJsonArray:(NSArray*)jsonArray includeAdmin:(BOOL)admin;

-(id)initWithDictionary:(NSDictionary*)dict;

@end
