//
//  RCMSyntaxHighlighter.m
//  MacClient
//
//  Created by Mark Lilback on 2/28/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import "RCMSyntaxHighlighter.h"

@interface RCMSyntaxHighlighter()
@property (nonatomic, strong) NSRegularExpression *quoteRegex;
@property (nonatomic, strong) NSRegularExpression *commentRegex;
@property (nonatomic, strong) NSRegularExpression *functionRegex;
@property (nonatomic, strong) NSRegularExpression *keywordRegex;
@end

@implementation RCMSyntaxHighlighter

@synthesize quoteRegex;
@synthesize commentRegex;
@synthesize functionRegex;
@synthesize keywordRegex;

+(id)sharedInstance
{
	static RCMSyntaxHighlighter *sInstance=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sInstance = [[self alloc] init];
	});
	return sInstance;
}

- (id)init
{
	if ((self = [super init])) {
		NSError *err=nil;
		self.quoteRegex = [NSRegularExpression regularExpressionWithPattern:@"([\"'])(?:\\\\\\\1|.)*?\\1" 
																	options:NSRegularExpressionDotMatchesLineSeparators error:&err];
		if (err)
			Rc2LogError(@"error compiling quote regex: %@", err);
		self.keywordRegex = [NSRegularExpression regularExpressionWithPattern:@"\\b(function|if|break|next|repeat|else|for|return|switch|while|in|invisible|pi|TRUE|FALSE|NULL|NA|NaN|Inf|T|F|=|<-|<<-|->|->>|==|<>|<|>|<=|>=|!|&{1,2}|\\-|\\+|\\*|\\/)\\b" options:0 error:&err];
		if (err)
			Rc2LogError(@"error compiling keyword regex: %@", err);
		self.functionRegex = [NSRegularExpression regularExpressionWithPattern:@"([0-9A-Za-z.][0-9A-Za-z._]*)\\s*(<-)?\\s*\\(" options:0 error:&err];
		if (err)
			Rc2LogError(@"error compiling function regex: %@", err);
		self.commentRegex = [NSRegularExpression regularExpressionWithPattern:@"#.*?\n" options:0 error:&err];
		if (err)
			Rc2LogError(@"error compiling comment regex: %@", err);
	}
	return self;
}

-(NSAttributedString*)syntaxHighlight:(NSAttributedString*)sourceStr
{
	NSDictionary *commentAttrs = [NSDictionary dictionaryWithObject:[NSColor colorWithCalibratedRed:0.064 green:0.428 blue:0.240 alpha:1.000] forKey:NSForegroundColorAttributeName];
	NSDictionary *keywordAttrs = [NSDictionary dictionaryWithObject:[NSColor colorWithCalibratedRed:0.616 green:0.096 blue:0.228 alpha:1.000] forKey:NSForegroundColorAttributeName];
	NSDictionary *functionAttrs = [NSDictionary dictionaryWithObject:[NSColor colorWithCalibratedRed:0.094 green:0.212 blue:1.000 alpha:1.000] forKey:NSForegroundColorAttributeName];
	NSMutableAttributedString *astr = [sourceStr mutableCopy];
	NSMutableDictionary *quotes = [NSMutableDictionary dictionary];
	
	int nextQuoteIndex=1;
	NSTextCheckingResult *tcr = [self.quoteRegex firstMatchInString:astr.string options:0 range:NSMakeRange(0, astr.length)];
	while (tcr) {
		NSString *key = [NSString stringWithFormat:@"~`%d`~", nextQuoteIndex++];
		[quotes setObject:[astr.string substringWithRange:tcr.range] forKey:key];
		[astr replaceCharactersInRange:tcr.range withString:key];
		tcr = [self.quoteRegex firstMatchInString:astr.string options:0 range:NSMakeRange(0, astr.length)];
	}
	[self.keywordRegex enumerateMatchesInString:astr.string options:0 range:NSMakeRange(0, astr.length) 
									 usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
	 {
		[astr addAttributes:keywordAttrs range:[results rangeAtIndex:1]];
	 }];
	[self.functionRegex enumerateMatchesInString:astr.string options:0 range:NSMakeRange(0, astr.length) 
									  usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
	 {
		 [astr addAttributes:functionAttrs range:[results rangeAtIndex:1]];
	 }];
	[self.commentRegex enumerateMatchesInString:astr.string options:0 range:NSMakeRange(0, astr.length) 
									 usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
	 {
		 [astr addAttributes:commentAttrs range:results.range];
	 }];

	//replace back the strings
	for (NSString *key in quotes.allKeys) {
		NSRange rng = [astr.string rangeOfString:key];
		[astr replaceCharactersInRange:rng withString:[quotes objectForKey:key]];
	}
	
	return astr;
}
@end
