//
//  RCCodeHighlighterSas.m
//  Rc2Client
//
//  Created by Mark Lilback on 9/17/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCCodeHighlighterSas.h"
#import "Rc2AppConstants.h"
#import <PEGKit/PEGKit.h>

@interface RCCodeHighlighterSas()
@property (nonatomic, strong) NSRegularExpression *sasCommentRegex;
@property (nonatomic, strong) NSRegularExpression *sasKeywordRegex;
@property (nonatomic, strong) NSRegularExpression *quoteRegex;
@end

@implementation RCCodeHighlighterSas
-(id)init
{
	if ((self = [super init])) {
		NSError *err=nil;
		self.quoteRegex = [NSRegularExpression regularExpressionWithPattern:@"([\"'])(?:\\\\\\\1|.)*?\\1"
																	options:NSRegularExpressionDotMatchesLineSeparators error:&err];
		if (err)
			Rc2LogError(@"error compiling quote regex: %@", err);
		self.sasCommentRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*\\*.*;\\s*\n" options:0 error:&err];
		if (err)
			Rc2LogError(@"error compiling sas comment regex: %@", err);
		self.sasKeywordRegex = [NSRegularExpression regularExpressionWithPattern:@"\\b(data|out|run|proc|var|end|output|normal|sort|quit|keep|drop|retain|format|class|set|table|merge|if|else|then|descending|eq|ne|avg|sum|model|input|=||<|>|\\-|\\+|\\*|\\/)\\b" options:0 error:&err];
		if (err)
			Rc2LogError(@"error compiling keyword regex: %@", err);
		
	}
	return self;
}

+(NSSet*)keywords
{
	static NSSet *keys;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSURL *url = [[NSBundle mainBundle] URLForResource:@"SasKeywords" withExtension:@"txt"];
		NSArray *keyArray = [[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"];
		NSAssert(keyArray, @"failed to load Sas keywords");
		keys = [[NSSet alloc] initWithArray:keyArray];
	});
	return keys;
}

-(void)highlightText:(NSMutableAttributedString *)content range:(NSRange)range
{
	[content removeAttribute:NSForegroundColorAttributeName range:range]; //remove old colors
	NSMutableDictionary *quotes = [NSMutableDictionary dictionary];
	
	int nextQuoteIndex=1;
	NSTextCheckingResult *tcr = [self.quoteRegex firstMatchInString:content.string options:0 range:NSMakeRange(0, content.length)];
	while (tcr) {
		NSString *key = [NSString stringWithFormat:@"~`%d`~", nextQuoteIndex++];
		[quotes setObject:[content.string substringWithRange:tcr.range] forKey:key];
		[content replaceCharactersInRange:tcr.range withString:key];
		tcr = [self.quoteRegex firstMatchInString:content.string options:0 range:NSMakeRange(0, content.length)];
	}
	id color = [colorMap objectForKey:kPref_SyntaxColor_Keyword];
	if (color) {
		[self.sasKeywordRegex enumerateMatchesInString:content.string options:0 range:NSMakeRange(0, content.length)
											usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
		{
			[content addAttribute:NSForegroundColorAttributeName value:color range:[results rangeAtIndex:1]];
		}];
	}
	color = [colorMap objectForKey:kPref_SyntaxColor_Comment];
	if (color) {
		[self.sasCommentRegex enumerateMatchesInString:content.string options:0 range:NSMakeRange(0, content.length)
											usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
		{
			if (results.numberOfRanges > 1)
				[content addAttribute:NSForegroundColorAttributeName value:color range:[results rangeAtIndex:1]];
		}];
	}
	//replace back the strings
	for (NSString *key in quotes.allKeys) {
		NSRange rng = [content.string rangeOfString:key];
		[content replaceCharactersInRange:rng withString:[quotes objectForKey:key]];
	}
}

@synthesize colorMap;
@end
