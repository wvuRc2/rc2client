//
//  RCAssignmentFile.h
//  Rc2Client
//
//  Created by Mark Lilback on 5/2/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCAssignment;

@interface RCAssignmentFile : NSObject
@property (nonatomic, weak) RCAssignment *assignment;
@property (nonatomic, strong, readonly) NSNumber *assignmentFileId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) BOOL readonly;

+(NSArray*)filesFromJSONArray:(NSArray*)json forCourse:(RCAssignment*)assignment;

-(id)initWithDictionary:(NSDictionary*)dict; //required to get the id

-(void)updateWithDictionary:(NSDictionary*)dict;

@end
