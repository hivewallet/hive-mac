//
//  HIBackupCenterWindowController.h
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferencesViewController.h>

#import "HIKeyObservingWindow.h"

@interface HIBackupCenterWindowController : NSViewController
    <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate, HIKeyObservingWindowDelegate,
    MASPreferencesViewController>

@end
