//
//  CBMacFontPrefsController.h
//  Rc2
//
//  Created by Mark Lilback on 4/10/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"

@interface RCMFontPrefs : NSViewController<NSTextFieldDelegate,MASPreferencesViewController>
-(IBAction)changeEditorFont:(id)sender;
-(IBAction)changeWorksheetFont:(id)sender;
@end
