//
//  RCSavedSession.h
//  Rc2
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import "_RCSavedSession.h"

@interface RCSavedSession : _RCSavedSession
@property (nonatomic, copy) NSArray *commandHistory;

//if multiple values are to be set, it best to get properties, set them, and then call setProperties
//each call to setProperties serializes a plist
@property (nonatomic, strong) NSMutableDictionary *properties;

-(id)propertyForKey:(NSString*)key;
//removes property if value is nil
-(void)setProperty:(id)value forKey:(NSString*)key;

-(BOOL)boolPropertyForKey:(NSString*)key;
-(void)setBoolProperty:(BOOL)val forKey:(NSString*)key;
@end
