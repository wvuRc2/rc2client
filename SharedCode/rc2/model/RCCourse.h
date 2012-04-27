//
//  RCCourse.h
//  MacClient
//
//  Created by Mark Lilback on 4/27/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCCourse : NSObject
@property (nonatomic, strong) NSNumber *classId;
@property (nonatomic, strong) NSNumber *courseId;
@property (nonatomic, strong) NSNumber *semesterId;
@property (nonatomic, copy) NSString *semesterName;
@property (nonatomic, copy) NSString *courseName;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray *assignments;

+(NSArray*)classesFromJSONArray:(NSArray*)json;

-(id)initWithDictionary:(NSDictionary*)dict; //required to get the classId

-(void)updateWithDictionary:(NSDictionary*)dict;
@end
