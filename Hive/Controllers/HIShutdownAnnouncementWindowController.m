//
//  HIShutdownAnnouncementWindowController.m
//  Hive
//
//  Created by Jakub Suder on 05/03/15.
//  Copyright (c) 2015 Hive Developers. All rights reserved.
//

#import "HIShutdownAnnouncementWindowController.h"

NSString * const ShutdownAnnouncementDisplayedKey = @"ShutdownAnnouncementDisplayed";

@interface HIShutdownAnnouncementWindowController ()

@property (nonatomic) BOOL messageAcknowledged;
@property (nonatomic, weak) IBOutlet NSTextField *textBox;

@end


@implementation HIShutdownAnnouncementWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:self.className];

    if (self) {
        self.messageAcknowledged = NO;
    }

    return self;
}

- (void)awakeFromNib {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:self.textBox.stringValue];

    [string addAttribute:NSFontAttributeName
                   value:self.textBox.font
                   range:NSMakeRange(0, string.string.length)];

    [self addLinkToString:string
   forOccurrencesOfString:@"Hive Mac FAQ"
                      URL:@"https://github.com/hivewallet/hive-mac/wiki/FAQ"];

    [self addLinkToString:string
   forOccurrencesOfString:@"Electrum"
                      URL:@"https://electrum.org"];

    [self addLinkToString:string
   forOccurrencesOfString:@"Bitcoin Core"
                      URL:@"https://bitcoin.org/en/download"];

    [self addLinkToString:string
   forOccurrencesOfString:@"Breadwallet"
                      URL:@"http://breadwallet.com"];

    [self addLinkToString:string
   forOccurrencesOfString:@"Multibit HD"
                      URL:@"https://multibit.org"];

    [self addLinkToString:string
   forOccurrencesOfString:@"BitGo"
                      URL:@"https://www.bitgo.com"];

    [self addLinkToString:string
   forOccurrencesOfString:@"Coinkite"
                      URL:@"https://coinkite.com"];

    self.textBox.attributedStringValue = string;
    self.textBox.allowsEditingTextAttributes = YES;
    self.textBox.selectable = YES;

    [self.window center];
}

- (IBAction)okPressed:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:ShutdownAnnouncementDisplayedKey];
    [self close];
}

- (void)addLinkToString:(NSMutableAttributedString *)attributedString
 forOccurrencesOfString:(NSString *)query
                    URL:(NSString *)link {

    NSString *source = attributedString.string;

    NSInteger start = 0;

    for (;;) {
        NSRange foundRange = [source rangeOfString:query
                                           options:0
                                             range:NSMakeRange(start, source.length - start)];

        if (foundRange.location == NSNotFound) {
            break;
        } else {
            [attributedString addAttribute:NSLinkAttributeName
                                     value:link
                                     range:foundRange];
            [attributedString addAttribute:NSUnderlineStyleAttributeName
                                     value:@(NSSingleUnderlineStyle)
                                     range:foundRange];
            [attributedString addAttribute:NSForegroundColorAttributeName
                                     value:[NSColor blueColor]
                                     range:foundRange];

            start = foundRange.location + foundRange.length;
        }
    }
}

@end
