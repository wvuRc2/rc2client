//
//  RC2ServerAFNet1.h
//  RC2
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Rc2Server.h"
#import "AFHTTPClient.h"

@interface RC2ServerAFNet1 : NSObject<Rc2Server>
@property (nonatomic, strong, readonly) AFHTTPClient *httpClient;

@end
