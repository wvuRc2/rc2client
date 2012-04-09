//
//  RCMSyntaxHighlighter.h
//  MacClient
//
//  Created by Mark Lilback on 2/28/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCMSyntaxHighlighter : NSObject

+(id)sharedInstance;

-(NSAttributedString*)syntaxHighlightRCode:(NSAttributedString*)sourceStr;
-(NSAttributedString*)syntaxHighlightLatexCode:(NSAttributedString*)sourceStr;

@end
