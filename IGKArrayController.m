//
//  IGKArrayController.m
//  Ingredients
//
//  Created by Alex Gordon on 13/02/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKArrayController.h"


@implementation IGKArrayController

@synthesize predicate;
@synthesize sortDescriptors;

- (void)awakeFromNib
{
	[tableView setDataSource:self];
}

- (void)fetch
{
	NSManagedObjectContext *ctx = [[[NSApp delegate] kitController] managedObjectContext];
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:@"DocRecord" inManagedObjectContext:ctx]];
	[request setPredicate:predicate];
	[request setSortDescriptors:sortDescriptors];
	
	fetchedObjects = [ctx executeFetchRequest:request error:nil];
}
- (void)refresh
{
	[self fetch];
	
	[tableView reloadData];
	
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];;
	[tableView scrollRowToVisible:0];
	
	[[tableView delegate] tableViewSelectionDidChange:nil];
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
	
	if (row < 0 || row >= [fetchedObjects count])
		return;
	
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[tableView scrollRowToVisible:row];
	
	[[tableView delegate] tableViewSelectionDidChange:nil];
}

- (id)objectAtRow:(NSInteger)row
{
	if (row < 0 || row >= [fetchedObjects count])
		return nil;
	
	return [fetchedObjects objectAtIndex:row];
}

- (id)selection
{
	NSInteger row = [tableView selectedRow];
	
	if (row < 0 || row >= [fetchedObjects count])
		return nil;
	
	return [fetchedObjects objectAtIndex:row];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [fetchedObjects count];
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (row < 0 || row >= [fetchedObjects count])
		return nil;
	
	if ([[tableColumn identifier] isEqual:@"normalIcon"])
	{
		if (row == [tableView selectedRow])
			return [[fetchedObjects objectAtIndex:row] valueForKey:@"selectedIcon"];
	}
	
	return [[fetchedObjects objectAtIndex:row] valueForKey:[tableColumn identifier]];
	
	/*
	if ([[tableColumn identifier] isEqual:@"name"])
		return [[fetchedObjects objectAtIndex:row] valueForKey:@"name"];
	else if ([[tableColumn identifier] isEqual:@"normalIcon"])
		return [[fetchedObjects objectAtIndex:row] valueForKey:@"normalIcon"];
	
	return nil;
	*/
}

@end
