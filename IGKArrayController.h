//
//  IGKArrayController.h
//  Ingredients
//
//  Created by Alex Gordon on 13/02/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IGKArrayController : NSObject<NSTableViewDataSource, NSTableViewDelegate>
{
	IBOutlet NSTableView *tableView;
	
	NSPredicate *predicate;
	NSArray *sortDescriptors;
	
	NSArray *fetchedObjects;
}

@property (assign) NSPredicate *predicate;
@property (assign) NSArray *sortDescriptors;

- (void)refresh;

- (IBAction)selectPrevious:(id)sender;
- (IBAction)selectNext:(id)sender;

@end
