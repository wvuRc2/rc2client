//
//  SyntaxParserTests.m
//  Rc2Client
//
//  Created by Mark Lilback on 9/28/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "RCSyntaxParser.h"
#import "RCCodeHighlighterR.h"
#import "Rc2FileType.h"

@interface SyntaxParserTests : SenTestCase

@end

@implementation SyntaxParserTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRHighlighter
{
	RCCodeHighlighterR *rhigh = [[RCCodeHighlighterR alloc] init];
	STAssertNoThrow([rhigh highlightText:nil range:NSMakeRange(0, 24)], @"failed with nil text");
	NSMutableAttributedString *mstr = [NSMutableAttributedString attributedStringWithString:@"" attributes:nil];
	STAssertNoThrow([rhigh highlightText:mstr range:NSMakeRange(0, mstr.length)], @"failed empty string");
}

@end
