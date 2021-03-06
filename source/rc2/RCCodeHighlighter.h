//
//  RCCodeHighlighter.h
//  Rc2Client
//
//  Created by Mark Lilback on 9/12/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>



@protocol RCCodeHighlighter <NSObject>
/// a dictionary with the kPref_SyntaxColor_* constants as keys and (NS/UI)Colors as the values
@property (nonatomic, copy) NSDictionary *colorMap;

//highlights range of content with colors from colorMap
-(void)highlightText:(NSMutableAttributedString*)content range:(NSRange)range;
@end
