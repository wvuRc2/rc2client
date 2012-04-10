//
//  CBMacFontPrefsController.h
//  Rc2
//
//  Created by Mark Lilback on 4/10/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RCMFontPrefs : AMPreferenceModule<NSTextFieldDelegate>
-(IBAction)changeEditorFont:(id)sender;
-(IBAction)changeWorksheetFont:(id)sender;
@end
