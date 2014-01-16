//
//  HIWizardViewController.h
//  Hive
//
//  Created by Nikolaj Schumacher on 2014-01-12.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

@protocol HIWizardViewControllerDelegate<NSObject>

- (void)didCompleteWizardPage;
- (u_long)pagesLeft;

@end

@interface HIWizardViewController : NSViewController

@property (nonatomic, strong) id<HIWizardViewControllerDelegate> wizardDelegate;

@end
