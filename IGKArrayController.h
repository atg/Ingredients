//
//  IGKArrayController.h
//  Ingredients
//
//  Created by Alex Gordon on 13/02/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>

@interface IGKArrayController : NSObject<NSTableViewDataSource, NSTableViewDelegate>
{
	IBOutlet NSTableView *tableView;
	
	NSUInteger maxRows;
	
	NSPredicate *predicate;
	NSArray *sortDescriptors;
	
	NSArray *fetchedObjects;
	
	id vipObject;
	BOOL fetchContainsVipObject;
}

@property (assign) NSPredicate *predicate;
@property (assign) NSArray *sortDescriptors;
@property (assign) NSUInteger maxRows;

//The VIP object, if set, will sit at the very top of the the predicate or anything else
@property (assign) id vipObject;

- (void)refresh;
- (void)refreshAndSelectFirst:(BOOL)selectFirst renderSelection:(BOOL)renderSelection;

- (id)objectAtRow:(NSInteger)row;
- (id)selection;

- (IBAction)selectPrevious:(id)sender;
- (IBAction)selectNext:(id)sender;

@end
