//
//  RCMGeneralPrefs.m
//  MacClient
//
//  Created by Mark Lilback on 4/10/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "RCMGeneralPrefs.h"
#import "MCAppConstants.h"
#import "DropBlocks.h"
#import <DropboxOSX/DropboxOSX.h>
#import <libkern/OSAtomic.h>

@interface RCMGeneralPrefs()
@property (nonatomic, weak) IBOutlet NSButton *resetButton;
@property (nonatomic, weak) IBOutlet NSButton *dbButton;
@property (nonatomic, weak) IBOutlet NSTextField *dbDescField;
@property (atomic, assign) int32_t acctInfoLock;
@end

@implementation RCMGeneralPrefs

-(void)awakeFromNib
{
	[self.view setWantsLayer:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDropboxStatus) name:DBAuthHelperOSXStateChangedNotification object:nil];
	[self updateDropboxStatus];
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:DBAuthHelperOSXStateChangedNotification object:nil];
}

-(IBAction)toggleDropbox:(id)sender
{
	DBSession *session = [DBSession sharedSession];
	if (session.isLinked) {
		[session unlinkAll];
	} else {
		DBAuthHelperOSX *helper = [DBAuthHelperOSX sharedHelper];
		[helper authenticate];
	}
	[self performSelector:@selector(updateDropboxStatus) withObject:nil afterDelay:0.1];
}

-(void)updateDropboxStatus
{
	DBSession *session = [DBSession sharedSession];
	DBAuthHelperOSX *helper = [DBAuthHelperOSX sharedHelper];
	self.dbButton.enabled = !helper.isLoading;
	self.dbButton.title = session.isLinked ? @"Unlink" : @"Link";
	if (session.isLinked && _acctInfoLock == 0) {
		//use atomic swap to make sure we don't accidentally fire off a bunch if not responding
		if (OSAtomicCompareAndSwap32(0, 1, &_acctInfoLock)) {
			[DropBlocks loadAccountInfo:^(DBAccountInfo *metadata, NSError *error) {
				if (metadata)
					_dbDescField.stringValue = [metadata displayName];
				else
					NSLog(@"db load info got error:%@" , error);
				OSAtomicCompareAndSwap32(1, 0, &_acctInfoLock);
			}];
		}
	}
}

-(IBAction)resetWarnings:(id)sender
{
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	for (NSString *key in [MCAppConstants alertSupressionKeys])
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
