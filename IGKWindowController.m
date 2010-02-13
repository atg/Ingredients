//
//  IGKWindowController.m
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKWindowController.h"
#import "IGKApplicationDelegate.h"
#import "IGKHTMLGenerator.h"
#import "IGKSourceListWallpaperView.h"

@implementation IGKWindowController

@synthesize appDelegate;
@synthesize sideFilterPredicate;
@synthesize advancedFilterPredicate;
@synthesize shouldIndex;
@synthesize docsetFilterMode;

- (id) init
{
	self = [super init];
	if (self != nil) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indexedAllPaths:) name:@"IGKHasIndexedAllPaths" object:nil];

	}
	return self;
}
- (void)indexedAllPaths:(NSNotification *)notif
{
	[self stopIndexing];
}

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
	//[self setSideFilterPredicate:[NSPredicate predicateWithFormat:@"FALSEPREDICATE"]];
	//[self setAdvancedFilterPredicate:[NSPredicate predicateWithFormat:@"FALSEPREDICATE"]];
	
	if (shouldIndex)
		[self startIndexing];
	
	sideSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES comparator:^NSComparisonResult (id a, id b) {
		//NSLog(@"Called with: %@, Q: %@", a, sideSearchQuery);
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
	[objectsController setSortDescriptors:[NSArray arrayWithObject:sideSortDescriptor]];
	
	[searchViewPredicateEditor addRow:nil];
	
	//[objectsController setManagedObjectContext:[[[NSApp delegate] kitController] managedObjectContext]];	
	//[objectsController fetch:nil];
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
			CGFloat leftWidth = [sideSearchView frame].size.width;
						
			NSRect newFrame = [twoPaneSplitView frame];
			newFrame.origin.x = 0.0 - leftWidth - 1;
			newFrame.size.width = [contentView frame].size.width + leftWidth + 1;
			[twoPaneSplitView setEnabled:NO];

			[[twoPaneSplitView animator] setFrame:newFrame];		
		}
		
		// two-up -> search
		else if (modeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
		{
			[twoPaneView removeFromSuperview];

			[searchView setFrame:[contentView bounds]];
			[contentView addSubview:searchView];
		}
	}
	else if (currentModeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
	{
		// browser -> two-up
		if (modeIndex == CHDocumentationBrowserUIMode_TwoUp)
		{
			[[twoPaneSplitView animator] setFrame:[contentView frame]];	
		}
		
		// browser -> search
		else if (modeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
		{
			[twoPaneView removeFromSuperview];
			
			[searchView setFrame:[contentView bounds]];
			[contentView addSubview:searchView];
		}
	}
	else if (currentModeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
	{
		// search -> two-up
		if (modeIndex == CHDocumentationBrowserUIMode_TwoUp)
		{
			[searchView removeFromSuperview];
			
			[twoPaneView setFrame:[contentView bounds]];
			[contentView addSubview:twoPaneView];
			
			[twoPaneSplitView setFrame:[contentView frame]];	
		}
		
		// search -> browser
		else if (modeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
		{
			[searchView removeFromSuperview];
			
			[twoPaneView setFrame:[contentView bounds]];
			[contentView addSubview:twoPaneView];
			
			CGFloat leftWidth = [sideSearchView frame].size.width;
			NSRect newFrame = [twoPaneSplitView frame];
			newFrame.origin.x = 0.0 - leftWidth - 1;
			newFrame.size.width = [contentView frame].size.width + leftWidth + 1;
			[twoPaneSplitView setEnabled:NO];
			
			[twoPaneSplitView setFrame:newFrame];
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
	
	[self willChangeValueForKey:@"ui_currentModeIndex"];
	currentModeIndex = modeIndex;
	[self didChangeValueForKey:@"ui_currentModeIndex"];
}

- (IBAction)executeSearch:(id)sender
{
	[self executeSideSearch:[sender stringValue]];
}

- (IBAction)executeAdvancedSearch:(id)sender
{
	
}

- (IBAction)changeViewModeTagged:(id)sender
{	
	NSInteger selectedSegment = [sender tag];
	if (selectedSegment == 0)
		[self setMode:CHDocumentationBrowserUIMode_BrowserOnly];
	else if(selectedSegment == 1)
		[self setMode:CHDocumentationBrowserUIMode_TwoUp];
	else if(selectedSegment == 2)
		[self setMode:CHDocumentationBrowserUIMode_AdvancedSearch];
}
- (IBAction)backForward:(id)sender
{
	NSInteger selectedSegment = [sender selectedSegment];
	if(selectedSegment == 0)
		[browserWebView goBack:nil];
	else if(selectedSegment == 1)
		[browserWebView goForward:nil];
}
/*
- (IBAction)changeViewMode:(id)sender
{	
	NSInteger selectedSegment = [sender selectedSegment];
	if(selectedSegment == 0)
		[self setMode:CHDocumentationBrowserUIMode_BrowserOnly];
	else if(selectedSegment == 1)
		[self setMode:CHDocumentationBrowserUIMode_TwoUp];
	else if(selectedSegment == 2)
		[self setMode:CHDocumentationBrowserUIMode_AdvancedSearch];
}*/

@dynamic ui_currentModeIndex;

- (void)setUi_currentModeIndex:(NSNumber *)n
{
	[self setMode:[n intValue]];
}
- (NSNumber *)ui_currentModeIndex
{
	return [NSNumber numberWithInt:currentModeIndex];
}

- (NSNumber *)ui_docsetFilterMode
{
	return [NSNumber numberWithInteger:docsetFilterMode];
}
- (void)setUi_docsetFilterMode:(NSNumber *)n
{
	[self willChangeValueForKey:@"ui_docsetFilterMode"];
	docsetFilterMode = [n integerValue];
	[self didChangeValueForKey:@"ui_docsetFilterMode"];
	
	[self executeSearch:nil];
}


- (void)executeSideSearch:(NSString *)query
{
	sideSearchQuery = query;
	
	//Duck tape
	//if (![objectsController managedObjectContext])
	//	[objectsController setManagedObjectContext:[[[NSApp delegate] kitController] managedObjectContext]];	
		
	if([query length] > 0)
	{
		NSPredicate *fetchPredicate = nil;
		if (docsetFilterMode == CHDocsetFilterShowAll)
			fetchPredicate = [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", @"name", query];
		else
			fetchPredicate = [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@ && docset.platformFamily == %@", @"name", query, docsetFilterMode == CHDocsetFilterShowMac ? @"macosx" : @"iphoneos"];
			
		//[self setSideFilterPredicate:fetchPredicate];
		[objectsController setPredicate:fetchPredicate];
	}
	else {
		[objectsController setPredicate:[NSPredicate predicateWithValue:NO]];
		//[sideSearchViewResults deselectAll:nil];
	}
	
	[objectsController refresh];
	//[objectsController fetch:nil];
	//[sideSearchViewResults setNeedsDisplay:YES];
}


- (void)startIndexing
{
	wallpaperView = [[IGKSourceListWallpaperView alloc] initWithFrame:[[[twoPaneSplitView subviews] objectAtIndex:0] bounds]];
	[wallpaperView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[[[twoPaneSplitView subviews] objectAtIndex:0] addSubview:wallpaperView];
	
	[sideSearchViewField setEnabled:NO];
	[sideSearchViewField setEditable:NO];
	
	[[browserWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:
											 [NSURL fileURLWithPath:
											  [[NSBundle mainBundle] pathForResource:@"tictactoe" ofType:@"html"]
											  ]
											 ]];
}
- (void)stopIndexing
{
	[wallpaperView removeFromSuperview];
	
	[sideSearchViewField setEnabled:YES];
	[sideSearchViewField setEditable:YES];
	
	//[objectsController setManagedObjectContext:[[[NSApp delegate] kitController] managedObjectContext]];
	
	//[objectsController fetch:nil];
}

- (void)setAdvancedFilterPredicate:(NSPredicate *)pred
{
	advancedSearchPredicate = pred;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	if ([NSStringFromSelector(command) isEqual:@"moveUp:"])
	{
		[objectsController selectPrevious:nil];
		return YES;
	}
	else if ([NSStringFromSelector(command) isEqual:@"moveDown:"])
	{
		[objectsController selectNext:nil];
		return YES;
	}
	else if ([NSStringFromSelector(command) isEqual:@"insertNewline:"])
	{
		[[browserWebView window] makeFirstResponder:browserWebView];
	}
	else if ([NSStringFromSelector(command) isEqual:@"cancelOperation:"])
	{
		
	}
	
	return NO;
}


#pragma mark -
#pragma mark Table View Delegate 

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([[aNotification object] isEqual:sideSearchViewResults])
	{
		
		if ([objectsController selection] == nil)
		{
			[[browserWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:
													 [NSURL fileURLWithPath:
													  [[NSBundle mainBundle] pathForResource:@"no_selection" ofType:@"html"]
													  ]
													 ]];
			return;
		}
		
		IGKHTMLGenerator *generator = [[IGKHTMLGenerator alloc] init];
		[generator setContext:[[[NSApp delegate] valueForKey:@"kitController"] managedObjectContext]];
		[generator setManagedObject:[objectsController selection]];
		[generator setDisplayType:IGKHTMLDisplayType_All];
		
		
		
		NSString *html = [generator html];
		[[browserWebView mainFrame] loadHTMLString:html
										   baseURL:[[NSBundle mainBundle] resourceURL]];
		
	}
}



@end
