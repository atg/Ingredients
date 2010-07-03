//
//  IGKBackForwardManager.m
//  Ingredients
//
//  Created by Alex Gordon on 07/03/2010.
//  Written in 2010 by Fileability.
//

#import "IGKBackForwardManager.h"


@interface IGKBackForwardManager ()

- (void)loadItem:(WebHistoryItem *)item;

@end


@implementation IGKBackForwardManager

@synthesize webView;
@synthesize delegate;
@synthesize menuStack;

- (id)init
{
	if (self = [super init])
	{
		backStack = [[NSMutableArray alloc] init];
		forwardStack = [[NSMutableArray alloc] init];
		
	}
	return self;
}


- (void)visitPage:(WebHistoryItem *)item
{	
	//If item has the same URL as currentItem, we ignore it
	NSString *itemURL = [item URLString];
	NSString *currentItemURL = [currentItem URLString];
	NSURL *newURL = [NSURL URLWithString:itemURL];
	if ([itemURL length] && [currentItemURL length] && ([newURL isEqual:[NSURL URLWithString:currentItemURL]] || [[newURL scheme] isEqual:@"file"]))
	{
		return;
	}
	
	//Push currentItem onto backStack, if it exists
	if (currentItem)
	{
		[self willChangeValueForKey:@"backStack"];
		[backStack addObject:currentItem];
		[[WebHistory optionalSharedHistory] addItems:[NSArray arrayWithObject:item]];
		
		[self didChangeValueForKey:@"backStack"];
	}
	
	currentItem = item;
	
	//Dump whatever's in forwardStack
	[self willChangeValueForKey:@"forwardStack"];
	[forwardStack removeAllObjects];
	[self didChangeValueForKey:@"forwardStack"];
	
	if ([delegate respondsToSelector:@selector(backForwardManagerUpdatedLists:)])
		[delegate backForwardManagerUpdatedLists:self];
}

- (void)loadItem:(WebHistoryItem *)item
{	
	NSURL *url = [NSURL URLWithString:[item URLString]];
	
	if ([delegate respondsToSelector:@selector(loadURL:recordHistory:)])
		[delegate loadURL:url recordHistory:NO];
}
- (BOOL)canGoBack
{
	if ([backStack count] > 0)
		return YES;
	
	return NO;
}
- (BOOL)canGoForward
{
	if ([forwardStack count] > 0)
		return YES;
	
	return NO;
}
- (IBAction)goBack:(id)sender
{
	[self goBackBy:1];
}
- (IBAction)goForward:(id)sender
{
	[self goForwardBy:1];
}


- (void)goBackBy:(NSInteger)amount
{	
	//Check that there's a page to go back to
	if ([backStack count] == 0)
	{
		return;
	}
	
	//Check that amount is in range
	if (amount < 1 || amount > [backStack count])
	{
		return;
	}
	
	if (currentItem || amount > 1)
	{
		[self willChangeValueForKey:@"forwardStack"];
		
		//Push currentItem onto forwardStack, if it exists
		if (currentItem)
			[forwardStack addObject:currentItem];
		
		//Push the last [amount] objects into forwardStack
		if (amount > 1)
		{
			NSArray *subarray = [backStack subarrayWithRange:NSMakeRange([backStack count] - amount + 1, amount - 1)];
			for (id item in [subarray reverseObjectEnumerator])
			{
				[forwardStack addObject:item];
			}
		}
		
		[self didChangeValueForKey:@"forwardStack"];
	}
	
	//Pop amount objects off backStack and assign the last one to currentItem
	currentItem = [backStack objectAtIndex:[backStack count] - amount];
	
	[self willChangeValueForKey:@"backStack"];
	[backStack removeObjectsInRange:NSMakeRange([backStack count] - amount, amount)];
	[self didChangeValueForKey:@"backStack"];
	
	if ([delegate respondsToSelector:@selector(backForwardManagerUpdatedLists:)])
		[delegate backForwardManagerUpdatedLists:self];
	
	//Load the page we're going back to
	[self loadItem:currentItem];
}
- (void)goForwardBy:(NSInteger)amount
{	
	//Check that there's a page to go forward to
	if ([forwardStack count] == 0)
	{
		return;
	}
	
	//Check that amount is in range
	if (amount < 1 || amount > [forwardStack count])
	{
		return;
	}
	
	if (currentItem || amount > 1)
	{
		[self willChangeValueForKey:@"backStack"];
		
		//Push currentItem onto forwardStack, if it exists
		if (currentItem)
			[backStack addObject:currentItem];
		
		//Push the last [amount] objects into forwardStack
		if (amount > 1)
		{
			NSArray *subarray = [forwardStack subarrayWithRange:NSMakeRange([forwardStack count] - amount + 1, amount - 1)];
			for (id item in [subarray reverseObjectEnumerator])
			{
				[backStack addObject:item];
			}
		}
		
		[self didChangeValueForKey:@"backStack"];
	}
	
	//Pop amount objects off forwardStack and assign the last one to currentItem
	currentItem = [forwardStack objectAtIndex:[forwardStack count] - amount];
	
	[self willChangeValueForKey:@"forwardStack"];
	[forwardStack removeObjectsInRange:NSMakeRange([forwardStack count] - amount, amount)];
	[self didChangeValueForKey:@"forwardStack"];
	
	if ([delegate respondsToSelector:@selector(backForwardManagerUpdatedLists:)])
		[delegate backForwardManagerUpdatedLists:self];
	
	//Load the page we're going forward to
	[self loadItem:currentItem];
}

- (NSArray *)backList
{
	//Reverse backStack
	NSMutableArray *reverseCopy = [[NSMutableArray alloc] initWithCapacity:[backStack count]];
	for (id x in [backStack reverseObjectEnumerator])
	{
		[reverseCopy addObject:x];
	}
	
	return reverseCopy;
}
- (WebHistoryItem *)backItem
{
	return [backStack lastObject];
}
- (WebHistoryItem *)currentItem
{
	return currentItem;
}
- (WebHistoryItem *)forwardItem
{
	return [forwardStack lastObject];
}
- (NSArray *)forwardList
{
	//Reverse forwardStack
	NSMutableArray *reverseCopy = [[NSMutableArray alloc] initWithCapacity:[forwardStack count]];
	for (id x in [forwardStack reverseObjectEnumerator])
	{
		[reverseCopy addObject:x];
	}
	
	return reverseCopy;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"\thistory = \n\tbackStack = %@\n\tcurrent = %@\n\tforwardStack = %@\n\t", backStack, currentItem, forwardStack];
}

@end