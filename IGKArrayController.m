//
//  IGKArrayController.m
//  Ingredients
//
//  Created by Alex Gordon on 13/02/2010.
//  Written in 2010 by Fileability.
//

#import "IGKArrayController.h"
#import "Ingredients_AppDelegate.h"
#import "IGKDocRecordManagedObject.h"
#import "IGKApplicationDelegate.h"

const NSTimeInterval timeoutInterval = 0.15;

@implementation IGKArrayController

@synthesize predicate;
@synthesize smartSortDescriptors;
@synthesize currentSortDescriptors;
@synthesize maxRows;
@synthesize vipObject;
@synthesize entityToFetch;

- (void)awakeFromNib
{
	[tableView setDataSource:self];
	entityToFetch = @"DocRecord";
}

- (void)fetch:(void (^)(NSArray *managedObjectIDs, BOOL fetchContainsVip))completionBlock
{
	if (!predicate)
		return;
	
	if (!currentSortDescriptors)
		currentSortDescriptors = smartSortDescriptors;
	
	NSManagedObjectContext *ctx = [[[NSApp delegate] kitController] managedObjectContext];
	dispatch_queue_t queue = [[[NSApp delegate] kitController] backgroundQueue];
	
	if (!queue)
		return;
	
	//Copy objects that may change while we're doing this
	NSPredicate *copiedPredicate = [predicate copy];
	NSArray *copiedCurrentSortDescriptors = [currentSortDescriptors copy];
	NSManagedObjectID *vipObjectID = [vipObject objectID];
	
	isSearching = YES;
	startedSearchTimeInterval = [NSDate timeIntervalSinceReferenceDate];
	[self performSelector:@selector(doTimeout) withObject:nil afterDelay:timeoutInterval];
	
	dispatch_async(queue, ^{
		
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		[request setEntity:[NSEntityDescription entityForName:entityToFetch inManagedObjectContext:ctx]];
		[request setPredicate:copiedPredicate];
				
		[request setFetchLimit:500];
		if (maxRows != 0 && maxRows < 500)
		{
			//Limit the list to 100 items. This could be changed to more, if requested, but my view is that if anybody needs more than 100, our sorting isn't smart enough
			[request setFetchLimit:maxRows];
		}
		
		//Sort results by priority, so that when we LIMIT our list, only the low priority items are cut
		[request setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:NO]]];
		
		//Fetch a list of objects
		NSArray *objects = [ctx executeFetchRequest:request error:nil];
		
		//NSFetchRequests and NSComparator-based sort descriptors apparently don't go together, so we can't tell the fetch request to sort using this descriptor
		//Besides, it's far better to be sorting 100 objects with our expensive comparator than 10000
		objects = [objects smartSort:[delegate sideSearchQuery]];
		//objects = [objects sortedArrayUsingDescriptors:copiedCurrentSortDescriptors];
		
		BOOL containsVIP = NO;
		
		//Put the object IDs into an array
		NSMutableArray *objectIDs = [[NSMutableArray alloc] initWithCapacity:[objects count]];
		for (NSManagedObject *obj in objects)
		{
			id objid = [obj objectID];
			[objectIDs addObject:objid];
			
			if (!containsVIP && [vipObjectID isEqual:objid])
				containsVIP = YES;
		}
		
		//Run the completion block on the main thread
		dispatch_async(dispatch_get_main_queue(), ^{
			
			isSearching = NO;
			
			if ([delegate respondsToSelector:@selector(arrayControllerFinishedSearching:)])
				[delegate arrayControllerFinishedSearching:self];
			
			completionBlock(objectIDs, containsVIP);
		});
	});
}
- (void)refresh
{
	[self refreshAndSelectIndex:0 renderSelection:YES];
}

- (void)doTimeout
{
	if (!isSearching)
		return;
	if (startedSearchTimeInterval + timeoutInterval >= [NSDate timeIntervalSinceReferenceDate])
		return;
	
	if ([delegate respondsToSelector:@selector(arrayControllerTimedOut:)])
		[delegate arrayControllerTimedOut:self];
}


//This method is PRIVATE!
- (void)fetchFromRefresh:(NSManagedObjectContext *)ctx managedObjectIDs:(NSArray *)managedObjectIDs fetchContainsVip:(BOOL)fetchContainsVip
{
	fetchContainsVipObject = fetchContainsVip;
	
	fetchedObjects = [[NSMutableArray alloc] initWithCapacity:[managedObjectIDs count]];
	for (NSManagedObjectID *objID in managedObjectIDs)
	{
		[fetchedObjects addObject:[ctx objectWithID:objID]];
	}
	
	[tableView reloadData];
}

- (void)refreshAndSelectObject:(IGKDocRecordManagedObject *)obj renderSelection:(BOOL)renderSelection
{
	NSManagedObjectContext *ctx = [[[NSApp delegate] kitController] managedObjectContext];
	
	//Fetch a new list of objects and refresh the table
	[self fetch:^ (NSArray *managedObjectIDs, BOOL fetchContainsVip) {
		[self fetchFromRefresh:ctx managedObjectIDs:managedObjectIDs fetchContainsVip:fetchContainsVip];
		
		if (obj)
		{
			NSUInteger ind = [fetchedObjects indexOfObject:obj];
			if (ind != NSNotFound)
			{
				//Select the first row, scroll to it, and notify the delegate
				[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:ind] byExtendingSelection:NO];;
				[tableView scrollRowToVisible:ind];
				
				if (renderSelection)
					[[tableView delegate] tableViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:tableView]];
			}
		}
	}];
}
- (void)refreshAndSelectIndex:(NSInteger)idx renderSelection:(BOOL)renderSelection
{
	NSManagedObjectContext *ctx = [[[NSApp delegate] kitController] managedObjectContext];
	
	//Fetch a new list of objects and refresh the table
	[self fetch:^(NSArray *managedObjectIDs, BOOL fetchContainsVip) {
		[self fetchFromRefresh:ctx managedObjectIDs:managedObjectIDs fetchContainsVip:fetchContainsVip];
		
		if (idx != -1)
		{
			//Select the first row, scroll to it, and notify the delegate
			[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];;
			[tableView scrollRowToVisible:idx];
			
			if (renderSelection)
				[[tableView delegate] tableViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:tableView]];
		}
	}];
}

- (BOOL)canSelectPrevious
{
	NSInteger row = [tableView selectedRow] - 1;
	return !(row < 0 || row >= [fetchedObjects count]);
}
- (IBAction)selectPrevious:(id)sender
{	
	if (![self canSelectPrevious])
		return;
	
	NSInteger row = [tableView selectedRow] - 1;
	
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[tableView scrollRowToVisible:row];
	
	[[tableView delegate] tableViewSelectionDidChange:nil];
}

- (BOOL)canSelectNext
{
	NSInteger row = [tableView selectedRow] + 1;
	return !(row < 0 || row >= [self numberOfRowsInTableView:tableView]);
}
- (IBAction)selectNext:(id)sender
{
	if (![self canSelectNext])
		return;
	
	NSInteger row = [tableView selectedRow] + 1;
	
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

- (void)tableView:(NSTableView *)tv sortDescriptorsDidChange:(NSArray *)oldDescriptors
{	
	currentSortDescriptors = [tableView sortDescriptors];
	NSArray *generatedSortDescriptors = [currentSortDescriptors copy];
	
	if (![currentSortDescriptors count])
	{
		currentSortDescriptors = smartSortDescriptors;
	}
	else
	{
		id firstObject = [currentSortDescriptors objectAtIndex:0];
		id newSortDescriptor = firstObject;
		
		if ([[firstObject key] isEqual:@"xentity"])
		{
			newSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:[firstObject ascending] comparator:^ NSComparisonResult (id obja, id objb) {
				
				//So neither a nor b starts with q. Now we apply prioritization. Some types get priority over others. For instance, a class > method > typedef > constant
				NSUInteger objaPriority = [[obja valueForKey:@"priority"] shortValue];
				NSUInteger objbPriority = [[objb valueForKey:@"priority"] shortValue];
				
				//Higher priorities are better
				if (objaPriority > objbPriority)
					return NSOrderedAscending;
				else if (objaPriority < objbPriority)
					return NSOrderedDescending;
				
				//If the have the same priority, just compare the names of their entities (this is arbitrary, we just want to make sure there isn't an enum between two structs)
				return [[[obja entity] name] localizedCompare:[[objb entity] name]];
			}];
		}
		else if ([[firstObject key] isEqual:@"xcontainername"])
		{
			BOOL isAsc = [firstObject ascending];
			newSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES comparator:^ NSComparisonResult (id obja, id objb) {
				id a = [obja xcontainername];
				id b = [objb xcontainername];
				
				BOOL hasA = ([a length] != 0);
				BOOL hasB = ([b length] != 0);
				
				if (hasA == hasB)
				{
					NSComparisonResult r = [a localizedCompare:b];
					if (isAsc)
						return r;
					
					//If this is a descending sort, then invert the result of the comparison
					//We do this instead of using the ascending: option because items with an empty container name should always appear at the bottom, regardless of sort direction 
					if (r == NSOrderedAscending)
						return NSOrderedDescending;
					
					if (r == NSOrderedDescending)
						return NSOrderedAscending;
					
					return NSOrderedSame;
				}
				else if (hasA && !hasB)
				{
					return NSOrderedAscending;
				}
				
				return NSOrderedDescending;
			}];
		}
		
		currentSortDescriptors = [NSArray arrayWithObject:newSortDescriptor];
	}
	
	[self refresh];
	
	
	NSSortDescriptor *desc = [generatedSortDescriptors count] ? [generatedSortDescriptors objectAtIndex:0] : nil;
	for (NSTableColumn *column in [tableView tableColumns])
	{
		NSImage *image = nil;
		
		if ([[desc key] isEqual:[column identifier]])
		{
			if ([desc ascending])
				image = [NSImage imageNamed:@"NSAscendingSortIndicator"];
			else
				image = [NSImage imageNamed:@"NSDescendingSortIndicator"];
		}
		
		[tableView setIndicatorImage:image inTableColumn:column];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv
{
	return [fetchedObjects count] + ((vipObject && !fetchContainsVipObject) ? 1 : 0);
}
- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (row < 0 || row >= [fetchedObjects count])
		return nil;
	
	//Get the object at this row
	id fo /* sure */ = nil;
	if (vipObject && !fetchContainsVipObject)
	{
		if (row == 0)
			fo = vipObject;
		else
			fo = [fetchedObjects objectAtIndex:row - 1];
	}
	else
	{
		fo = [fetchedObjects objectAtIndex:row];
	}
	
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
	
	//*** Container Names ***
	if ([identifier isEqual:@"xcontainername"])
	{
		return [fo valueForKey:@"xcontainername"];
	}
	
	//*** Docset Names ***
	if ([identifier isEqual:@"xdocset"])
	{
		return [fo valueForKey:@"xdocset"];
	}
	
	
	return nil;
}

@end