//
//  IGKWindowController.m
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKWindowController.h"
#import "IGKApplicationDelegate.h"


@implementation IGKWindowController

@synthesize appDelegate;
@synthesize sideFilterPredicate;

- (NSString *)windowNibName
{
	return @"CHDocumentationBrowser";
	
}

- (void)windowDidLoad
{
	currentModeIndex = CHDocumentationBrowserUIMode_NeedsSetup;
	[self setMode:CHDocumentationBrowserUIMode_TwoUp];
	sideSearchQuery = @"";
	
	
	sideSearchResults = [[NSMutableArray alloc] init];
	sideFilterPredicate = nil;
	sideSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES comparator:^NSComparisonResult (id a, id b) {
		NSLog(@"Called with: %@, Q: %@", a, sideSearchQuery);
		if([sideSearchQuery length] == 0)
			return NSOrderedAscending;
		
		NSInteger qLength = [sideSearchQuery length];
		NSInteger aLength = [a length];
		NSInteger bLength = [b length];
		
		NSInteger l1 = abs(aLength - qLength);
		NSInteger l2 = abs(bLength - qLength);
		
		if (l1 == l2)
			return [a localizedCompare:b];
		else if(l1 < l2)
			return NSOrderedAscending;
		
		return NSOrderedDescending;
		
	}];
	[sideSearchArrayController setSortDescriptors:[NSArray arrayWithObject:sideSortDescriptor]];
	
	
}



- (void)close
{
	if ([appDelegate hasMultipleWindowControllers])
		[[appDelegate windowControllers] removeObject:self];
	
	[super close];
}

#pragma mark UI

- (void)setMode:(int)modeIndex
{
	//If we're already in this mode, bail
	if (modeIndex == currentModeIndex)
		return;
	
	if (currentModeIndex == CHDocumentationBrowserUIMode_TwoUp)
	{
		// two-up -> browser
		if (modeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
		{
			
		}
		
		// two-up -> search
		else if (modeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
		{
			
		}
	}
	else if (currentModeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
	{
		// browser -> two-up
		if (modeIndex == CHDocumentationBrowserUIMode_TwoUp)
		{
			
		}
		
		// browser -> search
		else if (modeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
		{
			
		}
	}
	else if (currentModeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
	{
		// search -> two-up
		if (modeIndex == CHDocumentationBrowserUIMode_TwoUp)
		{
			
		}
		
		// search -> browser
		else if (modeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
		{
			
		}
	}
	else if (currentModeIndex == CHDocumentationBrowserUIMode_NeedsSetup)
	{
		//Set up subviews of the two-up view
		//Main
		[twoPaneView setFrame:[contentView bounds]];
		
		//Browser
		[browserView setFrame:[[[twoPaneSplitView subviews] objectAtIndex:1] bounds]];
		[[[twoPaneSplitView subviews] objectAtIndex:1] addSubview:browserView];
		
		//Side search
		[sideSearchView setFrame:[[[twoPaneContentsSplitView subviews] objectAtIndex:0] bounds]];
		[[[twoPaneContentsSplitView subviews] objectAtIndex:0] addSubview:sideSearchView];
		
		//Table of contents
		[tableOfContentsView setFrame:[[[twoPaneContentsSplitView subviews] objectAtIndex:1] bounds]];
		[[[twoPaneContentsSplitView subviews] objectAtIndex:1] addSubview:tableOfContentsView];
		
		
		//Set up the search view
		[searchView setFrame:[contentView bounds]];
		
		
		// none -> two-up
		if (modeIndex == CHDocumentationBrowserUIMode_TwoUp || modeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
		{
			[contentView addSubview:twoPaneView];
			
			// none -> browser
			if (modeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
			{
				CGFloat leftWidth = [[[twoPaneContentsSplitView subviews] objectAtIndex:0] bounds].size.width;
				
				[twoPaneSplitView setEnabled:NO];
				
				NSRect newFrame = [twoPaneSplitView frame];
				newFrame.origin.x = - leftWidth - 1;
				newFrame.size.width = [twoPaneView frame].size.width + leftWidth + 1;
				[twoPaneSplitView setFrame:newFrame];
			}
		}
		
		//none -> search
		else if (modeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
		{
			[contentView addSubview:searchView];
		}
	}
}

- (IBAction)executeSearch:(id)sender
{
	[self executeSideSearch:[sender stringValue]];
	
}


- (void)executeSideSearch:(NSString *)query
{
	sideSearchQuery = query;
	
	if([query length] > 0)
	{
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", @"name", query];
		NSLog(@"Pred: %@", fetchPredicate);
		[self setSideFilterPredicate:fetchPredicate];
	}
	else {
		[self setSideFilterPredicate:nil];
	}

}


@end
