//
//  LogMessage.h
//  LogWatcher
//
//  Created by Mark Lilback on 9/24/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LogMessage : NSObject
-(id)initWithDictionary:(NSDictionary*)dict;

@property (nonatomic, readonly) NSString *client;
@property (nonatomic, readonly) NSNumber *level;
@property (nonatomic, readonly) NSNumber *context;
@property (nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) NSString *message;
@property (nonatomic, readonly) NSDate *date;
@end
