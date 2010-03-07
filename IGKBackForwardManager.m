//
//  IGKBackForwardManager.m
//  Ingredients
//
//  Created by Alex Gordon on 07/03/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKBackForwardManager.h"


@interface IGKBackForwardManager ()

- (void)loadItem:(WebHistoryItem *)item;

@end


@implementation IGKBackForwardManager

@synthesize webView;
@synthesize delegate;

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
	NSLog(@"Visit page = %@", item);
	
	//If item has the same URL as currentItem, we ignore it
	NSString *itemURL = [item URLString];
	NSString *currentItemURL = [currentItem URLString];
	if ([itemURL length] && [currentItemURL length] && [[NSURL URLWithString:itemURL] isEqual:[NSURL URLWithString:currentItemURL]])
		return;
	
	//Push currentItem onto backStack, if it exists
	if (currentItem)
	{
		[backStack addObject:currentItem];
	}
	
	currentItem = item;
}

- (void)loadItem:(WebHistoryItem *)item
{
	NSLog(@"Load item = %@", item);
	
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
	NSLog(@"goBack = %@", backStack);
	
	//Check that there's a page to go back to
	if ([backStack count] == 0)
		return;
	
	//Push currentItem onto forwardStack, if it exists
	if (currentItem)
	{
		[forwardStack addObject:currentItem];
	}
	
	//Pop an object off backStack and assign it to currentItem
	currentItem = [backStack lastObject];
	[backStack removeLastObject];
	
	//Load the page we're going back to
	[self loadItem:currentItem];
}
- (IBAction)goForward:(id)sender
{
	//Check that there's a page to go forward to
	if ([forwardStack count] == 0)
		return;
	
	//Push currentItem onto backStack, if it exists
	if (currentItem)
	{
		[backStack addObject:currentItem];
	}
	
	//Pop an object off forwardStack and assign it to currentItem
	currentItem = [forwardStack lastObject];
	[forwardStack removeLastObject];
	
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

@end
