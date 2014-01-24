//
//  SyntaxParserTests.m
//  Rc2Client
//
//  Created by Mark Lilback on 9/28/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RCSyntaxParser.h"
#import "RCCodeHighlighterR.h"
#import "Rc2FileType.h"
#import "Rc2AppConstants.h"

@interface SyntaxParserTests : XCTestCase

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
	rhigh.colorMap = @{kPref_SyntaxColor_Keyword:[NSColor blueColor]};
	XCTAssertNoThrow([rhigh highlightText:nil range:NSMakeRange(0, 24)], @"failed with nil text");
	NSMutableAttributedString *mstr = [NSMutableAttributedString attributedStringWithString:@"" attributes:nil];
	XCTAssertNoThrow([rhigh highlightText:mstr range:NSMakeRange(0, mstr.length)], @"failed empty string");
	[mstr appendString:@"plot(rnorm(22))"];
	[rhigh highlightText:mstr range:NSMakeRange(0, mstr.length)];
	NSRange matchRange;
	XCTAssertNotNil([mstr attribute:NSForegroundColorAttributeName atIndex:1 effectiveRange:&matchRange], @"failed to get color for plot");
}

@end
