//
//  RCSessionUser.h
//  iPadClient
//
//  Created by Mark Lilback on 2/17/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCSessionUser : NSObject
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *login;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSNumber *userId;
@property (nonatomic, strong) NSNumber *sid;
@property (nonatomic, assign) BOOL master;
@property (nonatomic, assign) BOOL control;
@property (nonatomic, assign) BOOL handRaised;

- (id)initWithDictionary:(NSDictionary*)dict;
@end
