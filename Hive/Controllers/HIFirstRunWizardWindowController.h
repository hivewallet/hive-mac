//
//  HIFirstRunWizardWindowController.h
//  Hive
//
//  Created by Nikolaj Schumacher on 2014-01-12.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIKeyObservingWindow.h"
#import "HIWizardWindowController.h"

/*
 Wizard shown to the user on first run.
 */

@interface HIFirstRunWizardWindowController : HIWizardWindowController <HIKeyObservingWindowDelegate, NSWindowDelegate>
@end
