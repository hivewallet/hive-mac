//
//  HIWizardViewController.h
//  Hive
//
//  Created by Nikolaj Schumacher on 2014-01-12.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

@protocol HIWizardViewControllerDelegate<NSObject>

- (void)didCompleteWizardPage;

@end

@interface HIWizardViewController : NSViewController

@property (nonatomic, weak) id<HIWizardViewControllerDelegate> wizardDelegate;
@property (nonatomic, strong, readonly) NSResponder *initialFirstResponder;

- (void)viewWillAppear;

@end
