//
//  RCList.h
//  Rc2Client
//
//  Created by Mark Lilback on 11/11/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCVariable.h"

@interface RCList : RCVariable
-(NSString*)nameAtIndex:(NSUInteger)index;
-(BOOL)hasNames;
-(BOOL)hasValues;

-(NSInteger)indexOfVariable:(RCVariable*)var;

//basicallly initializes the list again. Used for nested lists when their data is fetched
-(void)assignListData:(NSDictionary*)dict;
	
@end

@interface RCEnvironment : RCList

@end