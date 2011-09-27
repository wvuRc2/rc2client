//
//  LogViewWindowController.m
//  LogWatcher
//
//  Created by Mark Lilback on 9/24/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "LogViewWindowController.h"
#import "LogMessage.h"

@interface LogViewWindowController()
@property (nonatomic, strong) WebSocket00 *websocket;
@property (nonatomic, strong) NSTimer *periodicTimer;
@property (nonatomic, strong) NSMenu *headerMenu;
@property (nonatomic, copy) NSArray *allTableColumns;
@property (nonatomic, strong) NSString *theURL;
@property (nonatomic, copy) NSString *serverTitle;
-(void)periodicTimerFired:(NSTimer*)timer;
-(void)toggleColumnVisibility:(id)sender;
@end

@implementation LogViewWindowController
@synthesize useEndDate=_useEndDate;
@synthesize useStartDate=_useStartDate;

-(id)initWithServerName:(NSString*)serverName urlString:(NSString*)serverUrl
{
	if ((self = [super initWithWindowNibName:@"LogViewWindowController"])) {
		self.theURL = serverUrl;
		self.serverTitle = serverName;
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		self.isLiveFeedMode = YES;
		self.useStartDate = [defaults boolForKey:@"UseStartDate"];
		self.useEndDate = [defaults boolForKey:@"UseEndDate"];
		self.endDate = [NSDate date];
		self.startDate = [NSDate dateWithTimeIntervalSinceNow:-3600];
	}
	
	return self;
}

-(void)dealloc
{
	[self.periodicTimer invalidate];
	[self.websocket close];
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	self.window.title = [NSString stringWithFormat:@"Log Watcher: %@", self.serverTitle];
	self.msgController.content = [NSMutableArray array];
	[self startWebSocket];
	self.periodicTimer = [NSTimer scheduledTimerWithTimeInterval:180 
														  target:self 
														selector:@selector(periodicTimerFired:) 
														userInfo:nil 
														 repeats:YES];
	self.allTableColumns = self.logTable.tableColumns;
	self.headerMenu = [[NSMenu alloc] initWithTitle:@""];
	self.headerMenu.autoenablesItems=NO;
	self.headerMenu.delegate = self;
	for (NSTableColumn *col in self.logTable.tableColumns) {
		NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:[col.headerCell stringValue]
													action:@selector(toggleColumnVisibility:) 
											 keyEquivalent:@""];
		mi.target = self;
		mi.representedObject = col;
		[self.headerMenu addItem:mi];
	}
	self.logTable.headerView.menu = self.headerMenu;
}

-(void)windowWillClose:(NSNotification *)notification
{
	[NSApp terminate:self];
	
}

#pragma mark - actions

-(void)toggleColumnVisibility:(id)sender
{
	NSTableColumn *col = [sender representedObject];
	[col setHidden:![col isHidden]];
}

-(void)startWebSocket
{
	self.websocket = [WebSocket00 webSocketWithURLString:self.theURL delegate:self origin:nil 
									 protocols:nil tlsSettings:nil verifyHandshake:YES];
	self.websocket.timeout = -1;
	[self.websocket open];
}

- (IBAction)doSearch:(id)sender
{
	self.isLiveFeedMode=NO;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	[dict setObject:@"search" forKey:@"cmd"];
	if (self.useStartDate) {
		[dict setObject:[NSNumber numberWithLong:[self.startDate timeIntervalSince1970]] forKey:@"start"];
		[dict setObject:[defaults objectForKey:@"StartOperator"] forKey:@"start-op"];
	}
	if (self.useEndDate) {
		[dict setObject:[NSNumber numberWithLong:[self.endDate timeIntervalSince1970]] forKey:@"end"];
		[dict setObject:[defaults objectForKey:@"EndOperator"] forKey:@"end-op"];
	}
	if (self.levelSearch) {
		[dict setObject:self.levelSearch forKey:@"level"];
		[dict setObject:[defaults objectForKey:@"LevelOperator"] forKey:@"level-op"];
	}
	if (self.contextSearch) {
		[dict setObject:self.contextSearch forKey:@"context"];
		[dict setObject:[defaults objectForKey:@"ContextOperator"] forKey:@"context-op"];
	}
	[dict setObject:@"sf92j5t9fk2kfkegfd110lsm" forKey:@"apikey"];
	NSError *err;
	NSData *json = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&err];
	if (err) {
		NSLog(@"error encoding JSON:%@", [err localizedDescription]);
	}
	[self.websocket send:[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]];
	self.msgController.content = [NSMutableArray array];
}

- (IBAction)doLiveFeed:(id)sender
{
	self.isLiveFeedMode = YES;
}

#pragma mark - websocket delegate

-(void)didOpen
{
	NSLog(@"ws open");
}

- (void) didClose: (NSError*) aError
{
	NSLog(@"ws close");
}

- (void) didReceiveError:(NSError*) error
{
	NSLog(@"web socket error: %@", [error localizedDescription]);
}

//-(void)didReceiveTextMessage:(NSString*)msg
-(void)didReceiveMessage:(NSString*)msg
{
	NSError *err;
	NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[msg dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&err];
	if (err) {
		NSLog(@"error parsing JSON: %@", [err localizedDescription]);
	} else {
		NSString *cmd = [dict objectForKey:@"cmd"];
		if ([cmd isEqualToString:@"messages"]) {
			if (self.isLiveFeedMode || [[dict objectForKey:@"search"] boolValue]) {
				for (NSDictionary *msgDict in [dict objectForKey:@"messages"]) {
					LogMessage *msg = [[LogMessage alloc] initWithDictionary:msgDict];
					[self.msgController addObjects:[NSArray arrayWithObject:msg]];
				}
			}
		}
	}
}

#pragma mark - menu delegate

-(void)menuWillOpen:(NSMenu *)menu
{
	for (NSMenuItem *mi in menu.itemArray) {
		NSTableColumn *col = [mi representedObject];
		[mi setState:col.isHidden ? NSOffState : NSOnState];
	}
}

#pragma mark - misc

-(void)periodicTimerFired:(NSTimer*)timer
{
	NSError *err;
	NSDictionary *dict = [NSDictionary dictionaryWithObject:@"echo" forKey:@"cmd"];
	NSData *json = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&err];
	[self.websocket send:[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]];
}

#pragma mark - accessors

-(void)setUseEndDate:(BOOL)use
{
	_useEndDate = use;
	[[NSUserDefaults standardUserDefaults] setBool:use forKey:@"UseEndDate"];
}

-(void)setUseStartDate:(BOOL)use
{
	_useStartDate = use;
	[[NSUserDefaults standardUserDefaults] setBool:use forKey:@"UseStartDate"];
}

@synthesize logTable;
@synthesize msgController;
@synthesize startDate;
@synthesize endDate;
@synthesize levelSearch;
@synthesize contextSearch;
@synthesize isLiveFeedMode;
@synthesize websocket;
@synthesize periodicTimer;
@synthesize headerMenu;
@synthesize allTableColumns;
@synthesize theURL;
@synthesize serverTitle;
@end
