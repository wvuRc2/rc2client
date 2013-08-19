//
//  AbstractProjectViewController.h
//  
//
//  Created by Mark Lilback on 8/15/13.
//
//

#import "Rc2NavBarChildProtocol.h"

@class RCProject;

@interface AbstractProjectViewController : UICollectionViewController<Rc2NavBarChildProtocol>
@property (nonatomic, weak) RCProject *selectedProject;

-(void)loginStatusChanged;

@end
