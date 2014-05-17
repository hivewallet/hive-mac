//
//  HIApplicationsViewController.h
//  Hive
//
//  Created by Bazyli Zygan on 28.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIViewController.h"

/*
 Manages the applications list view with application icons layed out in a grid.
 */

@interface HIApplicationsViewController : HIViewController

@property (nonatomic, readonly, getter = managedObjectContext) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly, getter = sortDescriptors) NSArray *sortDescriptors;

@end
