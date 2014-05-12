//
//  HINetworkConnectionMonitor.h
//  Hive
//
//  Created by Jakub Suder on 21/02/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

extern NSString * const HINetworkConnectionMonitorConnected;
extern NSString * const HINetworkConnectionMonitorDisconnected;

@interface HINetworkConnectionMonitor : NSObject

@property (nonatomic, readonly) BOOL connected;

@end
