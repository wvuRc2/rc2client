//
//  ProjectViewTransition.h
//  Rc2Client
//
//  Created by Mark Lilback on 8/20/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AbstractProjectViewController;

@interface ProjectViewTransition : NSObject<UIViewControllerAnimatedTransitioning>
-(id)initWithFromController:(AbstractProjectViewController*)fromVC toController:(AbstractProjectViewController*)toVC;
@end
