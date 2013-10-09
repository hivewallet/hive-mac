//
//  HIEditableImageView.m
//  Hive
//
//  Created by Jakub Suder on 09.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIEditableImageView.h"

@implementation HIEditableImageView

- (void)mouseDown:(NSEvent *)theEvent
{
    NSOpenPanel *dialog = [NSOpenPanel openPanel];
    dialog.allowedFileTypes = @[@"public.image"];

    [dialog beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            self.image = [[NSImage alloc] initWithContentsOfURL:dialog.URL];
            [self sendAction:self.action to:self.target];
        }
    }];
}

@end
