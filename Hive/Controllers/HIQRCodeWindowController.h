//
//  HIQRCodeWindowController.h
//  Hive
//
//  Created by Nikolaj Schumacher on 2014-02-09.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

/*
 Pop-up window showing an enlarged QR code.
 */
@interface HIQRCodeWindowController : NSWindowController

@property (nonatomic, copy) NSString *QRCodeString;
@property (nonatomic, copy) NSString *label;

@end
