//
//  MCProjectCollectionItem.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/25/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCProjectCollectionItem : NSCollectionViewItem <NSTextFieldDelegate>
@property (weak) IBOutlet NSTextField *itemLabel;

-(void)startNameEditing;
-(void)reloadItemDetails;
@end
