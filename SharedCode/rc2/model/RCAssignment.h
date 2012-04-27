//
//  RCAssignment.h
//  MacClient
//
//  Created by Mark Lilback on 4/27/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCAssignment : NSObject
@property (nonatomic, strong) NSNumber *assignmentId;
@property (nonatomic, strong) NSNumber *sortOrder;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, assign) BOOL locked;


+(NSArray*)assignmentsFromJSONArray:(NSArray*)json;

-(id)initWithDictionary:(NSDictionary*)dict; //required to get the id

-(void)updateWithDictionary:(NSDictionary*)dict;

@end
