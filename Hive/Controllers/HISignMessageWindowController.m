//
//  HISignMessageWindowController.m
//  Hive
//
//  Created by Jakub Suder on 01.04.2014.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HISignMessageWindowController.h"

@interface HISignMessageWindowController ()

@property (weak) IBOutlet NSTextField *messageBox;
@property (weak) IBOutlet NSTextField *signatureBox;

@end

@implementation HISignMessageWindowController

- (id)init {
    return [super initWithWindowNibName:self.className];
}

- (IBAction)cancelPressed:(id)sender {
    [self close];
}

- (IBAction)signPressed:(id)sender {
    // TODO
}

@end
