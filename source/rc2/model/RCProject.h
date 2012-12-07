//
//  RCProject.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/25/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCFileContainer.h"

@interface RCProject : NSObject<RCFileContainer>

@property (nonatomic, strong) NSNumber *projectId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, strong, readonly) NSArray *workspaces;
@property (nonatomic, copy, readonly) NSArray *files;
@property (nonatomic, readonly) BOOL userEditable;

+(NSArray*)projectsForJsonArray:(NSArray*)jsonArray includeAdmin:(BOOL)admin;
+(NSArray*)projectSortDescriptors;

-(id)initWithDictionary:(NSDictionary*)dict;

-(void)updateWithDictionary:(NSDictionary*)dict;
@end
