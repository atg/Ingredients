//
//  IGKArrayController.h
//  Ingredients
//
//  Created by Alex Gordon on 13/02/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>

@class IGKDocRecordManagedObject;

@interface IGKArrayController : NSObject<NSTableViewDataSource, NSTableViewDelegate>
{
	IBOutlet NSTableView *tableView;
	
	NSUInteger maxRows;
	
	NSPredicate *predicate;
	NSArray *smartSortDescriptors;
	NSArray *currentSortDescriptors;
	
	NSMutableArray *fetchedObjects;
	
	id vipObject;
	BOOL fetchContainsVipObject;
	
	BOOL sortIsAscending;
	NSString *sortColumn;
	NSString *entityToFetch;
	
	IBOutlet id delegate;
	BOOL isSearching;
	NSTimeInterval startedSearchTimeInterval;
}

@property (assign) NSPredicate *predicate;
@property (assign) NSArray *smartSortDescriptors;
@property (assign) NSArray *currentSortDescriptors;
@property (assign) NSUInteger maxRows;
@property (assign) NSString *entityToFetch;

//The VIP object, if set, will sit at the very top of the the predicate or anything else
@property (assign) id vipObject;

- (void)refresh;
- (void)refreshAndSelectObject:(IGKDocRecordManagedObject *)obj renderSelection:(BOOL)renderSelection;
- (void)refreshAndSelectIndex:(NSInteger)idx renderSelection:(BOOL)renderSelection;

- (id)objectAtRow:(NSInteger)row;
- (id)selection;

- (BOOL)canSelectPrevious;
- (BOOL)canSelectNext;

- (IBAction)selectPrevious:(id)sender;
- (IBAction)selectNext:(id)sender;

@end
