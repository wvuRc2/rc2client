//
//  RCMSyntaxHighlighter.m
//  MacClient
//
//  Created by Mark Lilback on 2/28/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "RCMSyntaxHighlighter.h"
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#import "RCMAppConstants.h"
#else
#import <CoreText/CoreText.h>
#import "AppConstants.h"
#endif

@interface RCMSyntaxHighlighter()
@property (nonatomic, strong) NSRegularExpression *quoteRegex;
@property (nonatomic, strong) NSRegularExpression *commentRegex;
@property (nonatomic, strong) NSRegularExpression *functionRegex;
@property (nonatomic, strong) NSRegularExpression *keywordRegex;
@property (nonatomic, strong) NSRegularExpression *latexCommentRegex;
@property (nonatomic, strong) NSRegularExpression *latexKeywordRegex;
@property (nonatomic, strong) NSRegularExpression *nowebChunkRegex;
@property (nonatomic, strong) NSRegularExpression *sasCommentRegex;
@property (nonatomic, strong) NSRegularExpression *sasKeywordRegex;
@property (nonatomic, strong) NSDictionary *commentAttrs;
@property (nonatomic, strong) NSDictionary *keywordAttrs;
@property (nonatomic, strong) NSDictionary *functionAttrs;
@end

@implementation RCMSyntaxHighlighter

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
			Rc2LogError(@"error compiling latex comment regex: %@", err);
		self.latexKeywordRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\\\([A-Za-z]+)" 
									options:NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionAnchorsMatchLines 
									error:&err];
		if (err)
			Rc2LogError(@"error compiling latex keyword regex: %@", err);
		self.nowebChunkRegex = [NSRegularExpression regularExpressionWithPattern:@"\n<<([^>]*)>>=\n+(.*?)\n@\n" 
																	options:NSRegularExpressionDotMatchesLineSeparators error:&err];
		if (err)
			Rc2LogError(@"error compiling noweb regex: %@", err);
		[self cacheAttributes];
		//listen for color changes. don't save token since this is a singleton
		[[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification 
														  object:nil 
														   queue:nil 
													  usingBlock:^(NSNotification *note) 
		{
			[self cacheAttributes];
		}];
	}
	return self;
}

-(void)setupSasRegexps
{
	NSError *err=nil;
	self.sasCommentRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*\\*.*;\\s*\n" options:0 error:&err];
	if (err)
		Rc2LogError(@"error compiling sas comment regex: %@", err);
	self.sasKeywordRegex = [NSRegularExpression regularExpressionWithPattern:@"\\b(data|out|run|proc|var|end|output|normal|sort|quit|keep|drop|retain|format|class|set|table|merge|if|else|then|descending|eq|ne|avg|sum|model|input|=||<|>|\\-|\\+|\\*|\\/)\\b" options:0 error:&err];
	if (err)
		Rc2LogError(@"error compiling keyword regex: %@", err);
}

-(void)cacheAttributes
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
	self.commentAttrs = [NSDictionary dictionaryWithObject:[NSColor colorWithHexString:[defs objectForKey:kPref_SyntaxColor_Comment]] forKey:NSForegroundColorAttributeName];
	self.keywordAttrs = [NSDictionary dictionaryWithObject:[NSColor colorWithHexString:[defs objectForKey:kPref_SyntaxColor_Keyword]] forKey:NSForegroundColorAttributeName];
	self.functionAttrs = [NSDictionary dictionaryWithObject:[NSColor colorWithHexString:[defs objectForKey:kPref_SyntaxColor_Function]] forKey:NSForegroundColorAttributeName];
#else
	self.commentAttrs = [NSDictionary dictionaryWithObject:(id)[UIColor colorWithHexString:[defs objectForKey:kPref_SyntaxColor_Comment]].CGColor forKey:(__bridge NSString*)kCTForegroundColorAttributeName];
	self.keywordAttrs = [NSDictionary dictionaryWithObject:(id)[UIColor colorWithHexString:[defs objectForKey:kPref_SyntaxColor_Keyword]].CGColor forKey:(__bridge NSString*)kCTForegroundColorAttributeName];
	self.functionAttrs = [NSDictionary dictionaryWithObject:(id)[UIColor colorWithHexString:[defs objectForKey:kPref_SyntaxColor_Function]].CGColor forKey:(__bridge NSString*)kCTForegroundColorAttributeName];
#endif
}

-(NSAttributedString*)syntaxHighlightCode:(NSAttributedString*)sourceStr ofType:(NSString*)fileExtension
{
	if ([fileExtension isEqualToString:@"R"])
		return [self syntaxHighlightRCode:sourceStr];
	else if ([fileExtension isEqualToString:@"RnW"] || [fileExtension isEqualToString:@"Rnw"])
		return [self syntaxHighlightLatexCode:sourceStr];
	else if ([fileExtension isEqualToString:@"sas"])
		return [self syntaxHighlightSasCode:sourceStr];
	return sourceStr;
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
		[astr addAttributes:self.keywordAttrs range:[results rangeAtIndex:1]];
	 }];
	[self.functionRegex enumerateMatchesInString:astr.string options:0 range:NSMakeRange(0, astr.length) 
									  usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
	 {
		 [astr addAttributes:self.functionAttrs range:[results rangeAtIndex:1]];
	 }];
	[self.commentRegex enumerateMatchesInString:astr.string options:0 range:NSMakeRange(0, astr.length) 
									 usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
	 {
		 [astr addAttributes:self.commentAttrs range:results.range];
	 }];

	//replace back the strings
	for (NSString *key in quotes.allKeys) {
		NSRange rng = [astr.string rangeOfString:key];
		[astr replaceCharactersInRange:rng withString:[quotes objectForKey:key]];
	}
	
	return astr;
}

-(NSAttributedString*)syntaxHighlightSasCode:(NSAttributedString*)sourceStr
{
	NSMutableAttributedString *astr = [sourceStr mutableCopy];
	NSMutableDictionary *quotes = [NSMutableDictionary dictionary];
	
	if (nil == self.sasKeywordRegex)
		[self setupSasRegexps];
	
	int nextQuoteIndex=1;
	NSTextCheckingResult *tcr = [self.quoteRegex firstMatchInString:astr.string options:0 range:NSMakeRange(0, astr.length)];
	while (tcr) {
		NSString *key = [NSString stringWithFormat:@"~`%d`~", nextQuoteIndex++];
		[quotes setObject:[astr.string substringWithRange:tcr.range] forKey:key];
		[astr replaceCharactersInRange:tcr.range withString:key];
		tcr = [self.quoteRegex firstMatchInString:astr.string options:0 range:NSMakeRange(0, astr.length)];
	}
	[self.sasKeywordRegex enumerateMatchesInString:astr.string options:0 range:NSMakeRange(0, astr.length) 
									 usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
	 {
		 [astr addAttributes:self.keywordAttrs range:[results rangeAtIndex:1]];
	 }];
	[self.sasCommentRegex enumerateMatchesInString:astr.string options:0 range:NSMakeRange(0, astr.length) 
									 usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
	 {
		 NSLog(@"found a sas comment");
		 [astr addAttributes:self.commentAttrs range:results.range];
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
			[astr addAttributes:self.commentAttrs range:[results rangeAtIndex:1]];
		}];
		
		[self.latexKeywordRegex enumerateMatchesInString:astr.string options:0 range:NSMakeRange(0, astr.length) 
											  usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
		{
			[astr addAttributes:self.keywordAttrs range:[results rangeAtIndex:0]];
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

@synthesize quoteRegex=_quoteRegex;
@synthesize latexCommentRegex=_latexCommentRegex;
@synthesize commentAttrs=_commentAttrs;
@synthesize commentRegex=_commentRegex;
@synthesize latexKeywordRegex=_latexKeywordRegex;
@synthesize functionAttrs=_functionAttrs;
@synthesize keywordAttrs=_keywordAttrs;
@synthesize keywordRegex=_keywordRegex;
@synthesize nowebChunkRegex=_nowebChunkRegex;
@synthesize functionRegex=_functionRegex;
@synthesize sasCommentRegex=_sasCommentRegex;
@synthesize sasKeywordRegex=_sasKeywordRegex;
@end
