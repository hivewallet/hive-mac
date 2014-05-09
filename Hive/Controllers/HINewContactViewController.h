//
//  HINewContactViewController.h
//  Hive
//
//  Created by Bazyli Zygan on 02.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIBox.h"
#import "HIContact.h"
#import "HITextField.h"
#import "HIViewController.h"

/*
 The contact edit form used for adding and editing contacts. Also handles editing of the user's profile if
 an HIProfile object is passed in place of a contact.
 */

@interface HINewContactViewController : HIViewController

@property (strong) id<HIPerson> contact;

@end
