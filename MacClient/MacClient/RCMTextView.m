//
//  RCMTextView.m
//  MacClient
//
//  Created by Mark Lilback on 10/16/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCMTextView.h"

@interface RCMTextView()
-(NSUInteger)findMatchingParen:(NSUInteger)closeLoc string:(NSString*)str;
@end

@implementation RCMTextView

-(void)insertText:(id)newText
{
	NSRange curLoc = self.selectedRange;
	[super insertText:newText];
	if ([@")" isEqualToString:newText])
	{
		NSString *txt = self.textStorage.string;
		NSUInteger openLoc = [self findMatchingParen:self.selectedRange.location-2 string:txt];
		if (openLoc != NSNotFound) {
			//flash the inserted character and it's matching item
			NSRange closeRange = NSMakeRange(curLoc.location, 1);
			NSRange openRange = NSMakeRange(openLoc, 1);
			NSColor *hcolor = [NSColor colorWithHexString:@"cccccc"];
			[self.textStorage addAttribute:NSBackgroundColorAttributeName value:hcolor range:openRange];
			[self.textStorage addAttribute:NSBackgroundColorAttributeName value:hcolor range:closeRange];
			RunAfterDelay(0.2, ^{
				[self.textStorage removeAttribute:NSBackgroundColorAttributeName range:openRange];
				[self.textStorage removeAttribute:NSBackgroundColorAttributeName range:closeRange];
			});
		}
	}
}

-(void)insertNewline:(id)sender
{
//	if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefAutoIndent]) {
		NSString *toInsert = @"\n";
		NSString *txt = self.textStorage.string;
		NSInteger curLoc = self.selectedRange.location;
		NSRange rng = [txt rangeOfString:@"\n" options:NSBackwardsSearch range:NSMakeRange(0, curLoc)];
		if (NSNotFound != rng.location) {
			rng.length=0;
			rng.location++;
			NSInteger i = rng.location;
			while (i < curLoc && ([txt characterAtIndex:i] == ' ' || [txt characterAtIndex:i] == '\t'))
			{
				i++;
				rng.length++;
			}
			if (rng.length > 0)
				toInsert = [toInsert stringByAppendingString:[txt substringWithRange:rng]];
		}
		[self.textStorage replaceCharactersInRange:self.selectedRange withString:toInsert];
//	} else {
//		[super insertNewline:sender];
//	}
}

-(NSUInteger)findMatchingParen:(NSUInteger)closeLoc string:(NSString*)str
{
	NSInteger stackCount=0;
	NSUInteger curLoc = closeLoc;
	while (curLoc > 0) {
		if ([str characterAtIndex:curLoc] == '(') {
			if (stackCount == 0)
				return curLoc;
			stackCount--;
		} else if ([str characterAtIndex:curLoc] == ')') {
			stackCount++;
			if (stackCount < 0)
				return NSNotFound;
		}
		curLoc--;
	}
	
	return NSNotFound;
}
@end

