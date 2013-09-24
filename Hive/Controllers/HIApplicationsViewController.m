//
//  HIApplicationsViewController.m
//  Hive
//
//  Created by Bazyli Zygan on 28.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIApplicationsViewController.h"
#import "HIContactRowView.h"
#import "HIContactCellView.h"
#import "HIApplication.h"
#import "HIApplicationRuntimeViewController.h"
#import "HINavigationController.h"

@interface HIApplicationsViewController ()

@end

@implementation HIApplicationsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.title = NSLocalizedString(@"Apps", @"Applications view title");
        self.iconName = @"apps";
    }

    return self;
}

- (NSManagedObjectContext *)managedObjectContext
{
    return DBM;
}

- (NSArray *)sortDescriptors
{
    return @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
}

- (void)loadView
{
    [super loadView];
    [_collectionView addObserver:self
                            forKeyPath:@"selectionIndexes"
                               options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                               context:nil];

}

- (void)dealloc
{
    [_collectionView removeObserver:self forKeyPath:@"selectionIndexes"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if([keyPath isEqualTo:@"selectionIndexes"])
    {
        if([_collectionView.selectionIndexes count] > 0)
        {
            if (self.navigationController.topViewController == self)
            {
                HIApplication * app = (HIApplication *)[[_arrayController arrangedObjects] objectAtIndex:_collectionView.selectionIndexes.lastIndex];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_collectionView setSelectionIndexes:[NSIndexSet indexSet]];
                });
                HIApplicationRuntimeViewController *sub = [HIApplicationRuntimeViewController new];
                sub.application = app;
                [self.navigationController pushViewController:sub animated:YES];
            }
        }
    }
}

@end
