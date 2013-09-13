//
//  RCHighlightingParser.m
//  Rc2Client
//
//  Created by Mark Lilback on 9/13/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCHighlightingParser.h"

@implementation RCHighlightingParser

-(void)parseRange:(NSRange)range
{
	[self.codeHighlighter highlightText:self.textStorage range:range];
}
@end
