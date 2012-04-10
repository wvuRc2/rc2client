//
//  RCMGeneralPrefs.m
//  MacClient
//
//  Created by Mark Lilback on 4/10/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import "RCMGeneralPrefs.h"
#import "RCMAppConstants.h"

@interface RCMGeneralPrefs()
@property (nonatomic, weak) IBOutlet NSButton *resetButton;
@end

@implementation RCMGeneralPrefs

-(void)awakeFromNib
{
	[self.view setWantsLayer:YES];
}

-(IBAction)resetWarnings:(id)sender
{
	for (NSString *key in [RCMAppConstants alertSupressionKeys]) 
		[_prefs removeObjectForKey:key];
}

@synthesize resetButton;
@end
