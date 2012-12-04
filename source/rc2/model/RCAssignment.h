//
//  RCAssignment.h
//  Rc2Client
//
//  Created by Mark Lilback on 4/27/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCCourse;

@interface RCAssignment : NSObject
@property (nonatomic, weak) RCCourse *course;
@property (nonatomic, strong) NSNumber *assignmentId;
@property (nonatomic, strong) NSNumber *sortOrder;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, assign) BOOL locked;
@property (nonatomic, copy) NSArray *files;

+(NSArray*)assignmentsFromJSONArray:(NSArray*)json forCourse:(RCCourse*)course;

-(id)initWithDictionary:(NSDictionary*)dict; //required to get the id

-(void)updateWithDictionary:(NSDictionary*)dict;

@end
