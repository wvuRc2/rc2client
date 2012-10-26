//
//  MacProjectCollectionView.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/25/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "MacProjectCollectionView.h"

@implementation MacProjectCollectionView

-(IBAction)deleteBackward:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(collectionView:deleteBackwards:)])
		[(id)self.delegate collectionView:self deleteBackwards:sender];
}

@end
