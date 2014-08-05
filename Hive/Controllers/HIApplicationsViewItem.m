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

        HIApplication *application = (HIApplication *) representedObject;
        NSDictionary *manifest = application.manifest;

        NSString *homepage = manifest[@"homepage"];
        if (homepage) {
            NSMenuItem *homepageItem = [[NSMenuItem alloc] init];
            homepageItem.target = self;
            homepageItem.action = @selector(visitHomepageItemClicked);
            homepageItem.title = NSLocalizedString(@"Visit application's site",
                                                   @"Entry in application icon context menu");
            [menu addItem:homepageItem];
        }

        NSString *email = manifest[@"contact"];
        if (email) {
            NSMenuItem *contactItem = [[NSMenuItem alloc] init];
            contactItem.target = self;
            contactItem.action = @selector(contactAuthorItemClicked);
            contactItem.title = NSLocalizedString(@"Contact the author", @"Entry in application icon context menu");
            [menu addItem:contactItem];
        }

        NSMenuItem *clearDataItem = [[NSMenuItem alloc] init];
        clearDataItem.target = self;
        clearDataItem.action = @selector(clearDataItemClicked);
        clearDataItem.title = @"Clear application data";
        [menu addItem:clearDataItem];

        NSMenuItem *deleteItem = [[NSMenuItem alloc] init];
        deleteItem.target = self;
        deleteItem.action = @selector(uninstallItemClicked);
        deleteItem.title = NSLocalizedString(@"Uninstall application", @"Entry in application icon context menu");
        [menu addItem:deleteItem];

        self.view.menu = menu;
    }
}

- (void)contactAuthorItemClicked {
    HIApplication *application = (HIApplication *) self.representedObject;
    NSDictionary *manifest = application.manifest;
    NSString *email = manifest[@"contact"];
    NSString *version = manifest[@"version"];
    NSString *title = [NSString stringWithFormat:@"%@ %@ feedback", application.name, version];

    NSString *mailto = [NSString stringWithFormat:@"mailto:%@?subject=%@",
                        [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                        [title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:mailto]];
}

- (void)visitHomepageItemClicked {
    HIApplication *application = (HIApplication *) self.representedObject;
    NSDictionary *manifest = application.manifest;
    NSString *homepage = manifest[@"homepage"];

    if ([homepage rangeOfString:@"://"].location == NSNotFound) {
        homepage = [@"http://" stringByAppendingString:homepage];
    }

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:homepage]];
}

- (void)uninstallItemClicked {
    HIApplication *application = (HIApplication *) self.representedObject;
    [[HIApplicationsManager sharedManager] requestApplicationRemoval:application];
}

- (void)clearDataItemClicked {
    HIApplication *application = (HIApplication *) self.representedObject;
    NSUInteger deleted = [[HIApplicationsManager sharedManager] clearCookiesForApplication:application];

    [[NSAlert alertWithMessageText:@"Application data deleted."
                     defaultButton:NSLocalizedString(@"OK", @"OK button title")
                   alternateButton:nil
                       otherButton:nil
         informativeTextWithFormat:@"%ld cookie(s) have been removed.", deleted] runModal];
}

@end
