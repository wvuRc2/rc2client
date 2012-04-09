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
@property (nonatomic, strong) NSRegularExpression *latexCommentRegex;
@property (nonatomic, strong) NSRegularExpression *nowebChunkRegex;
@property (nonatomic, strong) NSDictionary *commentAttrs;
@property (nonatomic, strong) NSDictionary *keywordAttrs;
@property (nonatomic, strong) NSDictionary *functionAttrs;
@end

@implementation RCMSyntaxHighlighter

@synthesize quoteRegex;
@synthesize commentRegex;
@synthesize functionRegex;
@synthesize keywordRegex;
@synthesize commentAttrs;
@synthesize keywordAttrs;
@synthesize functionAttrs;
@synthesize latexCommentRegex;
@synthesize nowebChunkRegex;

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
		self.latexCommentRegex = [NSRegularExpression regularExpressionWithPattern:@"(?<!\\\\)(%.*\n)" options:0 error:&err];
		if (err)
			Rc2LogError(@"error compiling latex quote regex: %@", err);
		self.nowebChunkRegex = [NSRegularExpression regularExpressionWithPattern:@"\n<<([^>]*)>>=\n+(.*?)\n@\n" 
																	options:NSRegularExpressionDotMatchesLineSeparators error:&err];
		if (err)
			Rc2LogError(@"error compiling noweb regex: %@", err);
		
		self.commentAttrs = [NSDictionary dictionaryWithObject:[NSColor colorWithCalibratedRed:0.064 green:0.428 blue:0.240 alpha:1.000] forKey:NSForegroundColorAttributeName];
		self.keywordAttrs = [NSDictionary dictionaryWithObject:[NSColor colorWithCalibratedRed:0.616 green:0.096 blue:0.228 alpha:1.000] forKey:NSForegroundColorAttributeName];
		self.functionAttrs = [NSDictionary dictionaryWithObject:[NSColor colorWithCalibratedRed:0.094 green:0.212 blue:1.000 alpha:1.000] forKey:NSForegroundColorAttributeName];
	}
	return self;
}

-(NSAttributedString*)syntaxHighlightRCode:(NSAttributedString*)sourceStr
{
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

-(NSAttributedString*)syntaxHighlightLatexCode:(NSAttributedString *)sourceStr
{
	@try {
		NSMutableAttributedString *astr = [sourceStr mutableCopy];
		NSMutableDictionary *chunks = [NSMutableDictionary dictionary];
		NSMutableDictionary *chunkRanges = [NSMutableDictionary dictionary];
		
		__block int nextChunkIndex=1;
		[self.nowebChunkRegex enumerateMatchesInString:astr.string options:0 range:NSMakeRange(0, astr.length) 
											usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
		{
			//mark any chunk title as a comment
			if ([results rangeAtIndex:1].length > 0)
				[astr setAttributes:self.commentAttrs range:[results rangeAtIndex:1]];
			NSMutableAttributedString *chunkBlock = [[astr attributedSubstringFromRange:results.range] mutableCopy];
			NSAttributedString *rcode = [astr attributedSubstringFromRange:[results rangeAtIndex:2]];
			rcode = [self syntaxHighlightRCode:rcode];
			NSInteger codeOffset = [results rangeAtIndex:2].location - results.range.location;
			//3 is for ending of chunk "\n@\n"
			NSRange codeRange = NSMakeRange(codeOffset, [results rangeAtIndex:2].length);
			[chunkBlock replaceCharactersInRange:codeRange withAttributedString:rcode];
			NSString *key = [NSString stringWithFormat:@"~`%d`~", nextChunkIndex++];
			[chunks setObject:chunkBlock forKey:key];
			[chunkRanges setObject:[NSValue valueWithRange:results.range] forKey:key];
		}];

		[self.latexCommentRegex enumerateMatchesInString:astr.string options:0 range:NSMakeRange(0, astr.length) 
										 usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
		{
			[astr addAttributes:commentAttrs range:[results rangeAtIndex:1]];
		}];
		
		//add back in chunks with highlighting
		for (NSString *key in chunks.allKeys) {
			NSRange rng = [[chunkRanges objectForKey:key] rangeValue];
			NSAttributedString *str = [chunks objectForKey:key];
			[astr replaceCharactersInRange:rng withAttributedString:str];
		}
		
		return astr;
	} @catch (NSException *e) {
		Rc2LogWarn(@"exception highlighting sweave", e);
	}
	return sourceStr;
}
@end
