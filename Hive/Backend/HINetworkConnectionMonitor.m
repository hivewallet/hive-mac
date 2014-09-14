//
//  HINetworkConnectionMonitor.m
//  Hive
//
//  Created by Jakub Suder on 21/02/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import <BitcoinJKit/HIBitcoinManager.h>
#import "HINetworkConnectionMonitor.h"

static const NSTimeInterval DisconnectionDelay = 30.0;

NSString * const HINetworkConnectionMonitorConnected = @"HINetworkConnectionMonitorConnected";
NSString * const HINetworkConnectionMonitorDisconnected = @"HINetworkConnectionMonitorDisconnected";

@interface HINetworkConnectionMonitor ()

@property (nonatomic, assign) BOOL connected;

@end


@implementation HINetworkConnectionMonitor

- (instancetype)init {
    self = [super init];

    if (self) {
        self.connected = YES;
        [[HIBitcoinManager defaultManager] addObserver:self
                                            forKeyPath:@"isConnected"
                                               options:NSKeyValueObservingOptionInitial
                                               context:NULL];
    }

    return self;
}

- (void)observeValueForKeyPath:(NSString *)path
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == [HIBitcoinManager defaultManager] && [path isEqual:@"isConnected"]) {
        if ([[HIBitcoinManager defaultManager] isConnected]) {
            if (self.connected) {
                HILogInfo(@"Connection timeout cancelled.");
                [[self class] cancelPreviousPerformRequestsWithTarget:self
                                                             selector:@selector(onDisconnect)
                                                               object:nil];
            } else {
                [self onConnect];
            }
        } else {
            HILogInfo(@"Starting network connection timeout (%.0fs).", DisconnectionDelay);
            [self performSelector:@selector(onDisconnect)
                       withObject:nil
                       afterDelay:DisconnectionDelay];
        }
    }
}

- (void)onConnect {
    HILogInfo(@"Network connection established.");
    self.connected = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:HINetworkConnectionMonitorConnected object:self];
}

- (void)onDisconnect {
    HILogWarn(@"Network connection lost.");
    self.connected = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:HINetworkConnectionMonitorDisconnected object:self];
}

- (void)dealloc {
    [[HIBitcoinManager defaultManager] removeObserver:self forKeyPath:@"isConnected"];
}

@end
