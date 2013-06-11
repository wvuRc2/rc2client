//
//  RCMGeneralPrefs.m
//  MacClient
//
//  Created by Mark Lilback on 4/10/12.
//  Copyright 2012 West Virginia University. All rights reserved.
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
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	for (NSString *key in [RCMAppConstants alertSupressionKeys])
		[prefs removeObjectForKey:key];
}

-(NSString*)identifier
{
	return @"GeneralPrefs";
}

-(NSImage*)toolbarItemImage
{
	return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

-(NSString*)toolbarItemLabel
{
	return @"General";
}

@end
