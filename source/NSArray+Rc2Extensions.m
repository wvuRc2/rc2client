//
//  NSArray+Rc2Extensions.m
//  Rc2Client
//
//  Created by Mark Lilback on 12/10/15.
//  Copyright © 2015 West Virginia University. All rights reserved.
//

#import "NSArray+Rc2Extensions.h"

@implementation NSArray (Rc2Extensions)
-(id)rc2_firstObjectWithValue:(id)value forKey:(NSString*)key
{
	for (id obj in self) {
		if ([value isEqual: [obj valueForKey:key]])
			return obj;
	}
	return nil;
}

@end
