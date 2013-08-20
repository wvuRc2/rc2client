//
//  Rc2NavBarChildProtocol.h
//  Rc2Client
//
//  Created by Mark Lilback on 8/19/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol Rc2NavBarChildProtocol <NSObject>
@property (nonatomic, copy, readonly) NSArray *standardLeftNavBarItems;
@property (nonatomic, copy, readonly) NSArray *standardRightNavBarItems;

@optional
-(id)workspaceForSettings;
@end
