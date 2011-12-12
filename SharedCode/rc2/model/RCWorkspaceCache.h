//
//  RCWorkspaceCache.h
//
//  Created by Mark Lilback on 12/12/11.
//  Copyright (c) 2011 . All rights reserved.
//

#import "_RCWorkspaceCache.h"

@interface RCWorkspaceCache : _RCWorkspaceCache
//if multiple values are to be set, it best to get properties, set them, and then call setProperties
//each call to setProperties serializes a plist
@property (nonatomic, strong) NSMutableDictionary *properties;

-(id)propertyForKey:(NSString*)key;
//removes property if value is nil
-(void)setProperty:(id)value forKey:(NSString*)key;

-(BOOL)boolPropertyForKey:(NSString*)key;
-(void)setBoolProperty:(BOOL)val forKey:(NSString*)key;
@end
