//
//  RCMSyntaxHighlighter.h
//  MacClient
//
//  Created by Mark Lilback on 2/28/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCMSyntaxHighlighter : NSObject

+(id)sharedInstance;

-(NSAttributedString*)syntaxHighlightCode:(NSAttributedString*)sourceStr ofType:(NSString*)fileExtension;

@end
