//
//  RCStuckies.h
//  MacClient
//
//  Created by Mark Lilback on 1/30/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import "Rc2Server.h"

@interface RCStuckies : Rc2Server

@end

@interface Rc2Server (Privates)
-(void)handleLoginResponse:(ASIHTTPRequest*)req forUser:(NSString*)user completionHandler:(Rc2SessionCompletionHandler)handler;
@end
