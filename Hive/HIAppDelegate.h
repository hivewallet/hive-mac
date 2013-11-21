//
//  HIAppDelegate.h
//  Hive
//
//  Created by Bazyli Zygan on 11.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <HockeySDK/HockeySDK.h>
#import <INAppStoreWindow/INAppStoreWindow.h>

@class HIContact;
@class HISendBitcoinsWindowController;

@interface HIAppDelegate : NSObject <NSApplicationDelegate, BITHockeyManagerDelegate>

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)openSendBitcoinsWindow:(id)sender;
- (IBAction)openCoinMapSite:(id)sender;
- (IBAction)showDebuggingInfo:(id)sender;
- (void)showExceptionWindowWithException:(NSException *)exception;
- (HISendBitcoinsWindowController *)sendBitcoinsWindowForContact:(HIContact *)contact;
- (HISendBitcoinsWindowController *)sendBitcoinsWindow;
- (NSURL *)applicationFilesDirectory;

@end
