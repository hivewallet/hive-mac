//
//  HIApplicationsViewItem.m
//  Hive
//
//  Created by Jakub Suder on 27/02/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIApplication.h"
#import "HIApplicationsManager.h"
#import "HIApplicationsViewItem.h"

@implementation HIApplicationsViewItem

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    if (self.view && representedObject) {
        NSMenu *menu = [[NSMenu alloc] init];

        NSMenuItem *deleteItem = [[NSMenuItem alloc] init];
        deleteItem.target = self;
        deleteItem.action = @selector(uninstallItemClicked);
        deleteItem.title = NSLocalizedString(@"Uninstall application", @"Entry in application icon context menu");
        [menu addItem:deleteItem];

        self.view.menu = menu;
    }
}

- (void)uninstallItemClicked {
    HIApplication *application = (HIApplication *) self.representedObject;
    [[HIApplicationsManager sharedManager] requestApplicationRemoval:application];
}

@end
