//
//  IGKArrayController.m
//  Ingredients
//
//  Created by Alex Gordon on 13/02/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKArrayController.h"
#import "Ingredients_AppDelegate.h"

@implementation IGKArrayController

@synthesize predicate;
@synthesize sortDescriptors;
@synthesize maxRows;
@synthesize vipObject;

- (void)awakeFromNib
{
	[tableView setDataSource:self];
}

- (void)fetch
{	
	//TODO: Eventually we want to fetch on another thread. There are still some synchronization issues to sort out
	//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
	
	NSManagedObjectContext *ctx = [[[NSApp delegate] kitController] managedObjectContext];
		
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:@"DocRecord" inManagedObjectContext:ctx]];
	[request setPredicate:predicate];
	
	if (maxRows != 0)
	{
		//Limit the list to 100 items. This could be changed to more, if requested, but my view is that if anybody needs more than 100, our sorting isn't smart enough
		[request setFetchLimit:maxRows];
	}
	
	//Sort results by priority, so that when we LIMIT our list, only the low priority items are cut
	[request setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:NO]]];
	
	//Fetch a list of <= 100 objects
	fetchedObjects = [ctx executeFetchRequest:request error:nil];
	
	//NSFetchRequests and NSComparator-based sort descriptors apparently don't go together, so we can't tell the fetch request to sort using this descriptor
	//Besides, it's far better to be sorting 100 objects with our expensive comparator than 10000
	fetchedObjects = [fetchedObjects sortedArrayUsingDescriptors:sortDescriptors];
	
	if ([fetchedObjects containsObject:vipObject])
		fetchContainsVipObject = YES;
	else
		fetchContainsVipObject = NO;
	
	//});
}
- (void)refresh
{
	[self refreshAndSelectFirst:YES renderSelection:NO];
}
- (void)refreshAndSelectFirst:(BOOL)selectFirst renderSelection:(BOOL)renderSelection
{
	//Fetch a new list of objects and refresh the table
	[self fetch];
	
	[tableView reloadData];
	
	if (selectFirst)
	{
		//Select the first row, scroll to it, and notify the delegate
		[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];;
		[tableView scrollRowToVisible:0];
		
		if (renderSelection)
			[[tableView delegate] tableViewSelectionDidChange:nil];
	}
}

- (IBAction)selectPrevious:(id)sender
{
	NSInteger row = [tableView selectedRow] - 1;
	
	if (row < 0 || row >= [fetchedObjects count])
		return;
	
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[tableView scrollRowToVisible:row];
	
	[[tableView delegate] tableViewSelectionDidChange:nil];
}
- (IBAction)selectNext:(id)sender
{
	NSInteger row = [tableView selectedRow] + 1;
	
	if (row < 0 || row >= [self numberOfRowsInTableView:tableView])
		return;
	
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[tableView scrollRowToVisible:row];
	
	[[tableView delegate] tableViewSelectionDidChange:nil];
}

- (id)objectAtRow:(NSInteger)row
{
	if (row < 0 || row >= [self numberOfRowsInTableView:tableView])
		return nil;
	
	if (vipObject && !fetchContainsVipObject)
	{
		if (row == 0)
			return vipObject;
		
		return [fetchedObjects objectAtIndex:row - 1];
	}
	else
		return [fetchedObjects objectAtIndex:row];
}

- (id)selection
{
	NSInteger row = [tableView selectedRow];
	
	if (row < 0 || row >= [self numberOfRowsInTableView:tableView])
		return nil;
	
	if (vipObject && !fetchContainsVipObject)
	{
		if (row == 0)
			return vipObject;
		
		return [fetchedObjects objectAtIndex:row - 1];
	}
	else
		return [fetchedObjects objectAtIndex:row];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv
{
	return [fetchedObjects count] + (vipObject && !fetchContainsVipObject ? 1 : 0);
}
- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (row < 0 || row >= [fetchedObjects count])
		return nil;
	
	//Get the object at this row
	id fo /* sure */ = nil;
	if (row == 0 && vipObject)
		fo = vipObject;
	else if (vipObject)
		fo = [fetchedObjects objectAtIndex:row - 1];
	else
		fo = [fetchedObjects objectAtIndex:row];
	
	id identifier = [tableColumn identifier];
	
	//*** Icons ***
	if ([identifier isEqual:@"normalIcon"])
	{
		if (row == [tableView selectedRow])
			return [fo valueForKey:@"selectedIcon"];
		else
			return [fo valueForKey:@"normalIcon"];
	}
	
	//*** Titles ***
	if ([identifier isEqual:@"name"])
	{
		return [fo valueForKey:@"name"];
	}
	
	return nil;
}

@end
