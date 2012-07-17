//
//  RCStudentAssignment.h
//  iPadClient
//
//  Created by Mark Lilback on 5/14/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCAssignment;

@interface RCStudentAssignment : NSObject
@property (nonatomic, weak) RCAssignment *assignment;
@property (nonatomic, copy) NSString *studentName;
@property (nonatomic, strong) NSNumber *studentId;
@property (nonatomic, strong) NSNumber *workspaceId;
@property (nonatomic, assign) BOOL turnedIn;
@property (nonatomic, strong) NSDate *dueDate;
@property (nonatomic, strong) NSNumber *grade;
@property (nonatomic, copy) NSArray *files;

-(id)initWithDictionary:(NSDictionary*)dict;
-(void)updateWithDictionary:(NSDictionary*)dict;
@end
