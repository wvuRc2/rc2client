//
//  MacSessionViewController.m
//  MacClient
//
//  Created by Mark Lilback on 10/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "MacSessionViewController.h"
#import "MCWebOutputController.h"
#import "Rc2Server.h"

@interface MacSessionViewController() {
	BOOL __didInit;
}
@property (nonatomic, strong) MCWebOutputController *outputController;
-(void)prepareForSession;
-(void)completeSessionStartup:(id)response;
@end

@implementation MacSessionViewController
@synthesize session=__session;

-(id)initWithSession:(RCSession*)aSession
{
	self = [super initWithNibName:@"MacSessionViewController" bundle:nil];
	if (self) {
		self.session = aSession;
		self.session.delegate = self;
	}
	return self;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	if (!__didInit) {
		self.outputController = [[MCWebOutputController alloc] init];
		NSView *croot = [self.splitView.subviews objectAtIndex:1];
		[croot addSubview:self.outputController.view];
		self.outputController.view.frame = croot.bounds;
		self.busy = YES;
		self.statusMessage = @"Connecting to server…";
		[self prepareForSession];
		__didInit=YES;
	}
}

-(IBAction)makeBusy:(id)sender
{
	self.busy = ! self.busy;
	self.statusMessage = @"hoo boy";
}

-(void)completeSessionStartup:(id)response
{
	[self.session updateWithServerResponse:response];
	[self.session startWebSocket];
}

-(void)prepareForSession
{
	[[Rc2Server sharedInstance] prepareWorkspace:self.session.workspace completionHandler:^(BOOL success, id response) {
		if (success) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self completeSessionStartup:response];
			});
		} else {
			//TODO: better error handling
			self.statusMessage = [NSString stringWithFormat:@"Error preparing workspace: (%@)", response];
		}
	}];
}

#pragma mark - session delegate

-(void)connectionOpened
{
	self.busy=NO;
	self.statusMessage = @"Connected";
}

-(void)connectionClosed
{
	self.statusMessage = @"Disconnected";
}

-(void)handleWebSocketError:(NSError*)error
{
	[self presentError:error];
}

-(void)processWebSocketMessage:(NSDictionary*)msg json:(NSString*)jsonString
{
	
}

-(void)performConsoleAction:(NSString*)action
{
	
}

-(void)displayImage:(NSString*)imgPath
{
	
}


#pragma mark - accessors/synthesizers

-(void)setSession:(RCSession *)session
{
	if (__session == session)
		return;
	if (__session) {
		[__session closeWebSocket];
		__session.delegate=nil;
	}
	__session = session;
}

@synthesize splitView;
@synthesize outputController;
@end

@implementation SessionView
@end