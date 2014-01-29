//
//  HIWizardBackupViewController.h
//  Hive
//
//  Created by Nikolaj Schumacher on 2014-01-19.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIKeyObservingWindow.h"
#import "HIWizardViewController.h"

/*
 First-run wizard page for setting up backups.
 */
@interface HIWizardBackupViewController : HIWizardViewController <HIKeyObservingWindowDelegate>
@end
