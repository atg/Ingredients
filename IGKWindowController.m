//
//  IGKWindowController.m
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Written in 2010 by Fileability.
//

#import "IGKWindowController.h"
#import "IGKApplicationDelegate.h"
#import "IGKHTMLGenerator.h"
#import "IGKSourceListWallpaperView.h"
#import "IGKArrayController.h"
#import "IGKBackForwardManager.h"
#import "IGKPredicateEditor.h"
#import "IGKDocRecordManagedObject.h"
#import "CHSymbolButtonImage.h"
#import "IGKSometimesCenteredTextCell.h"
#import "IGKFrecencyStore.h"

@interface IGKWindowController ()

- (void)startIndexing;
- (void)indexedAllPaths:(NSNotification *)notif;
- (void)stopIndexing;

- (void)advancedSearchDoubleAction:(id)sender;

- (void)executeSideSearch:(NSString *)query;
- (void)restoreAdvancedSearchStateIntoTwoUp:(BOOL)selectFirst;
- (void)sideSearchTableChangedSelection;

- (void)tableOfContentsChangedSelection;
- (void)registerDisplayTypeInTableView:(IGKHTMLDisplayType)type title:(NSString *)title;

- (void)loadManagedObject:(IGKDocRecordManagedObject *)mo tableOfContentsMask:(IGKHTMLDisplayTypeMask)tm URL:(NSURL *)url;

- (void)setMode:(int)modeIndex;
- (IGKArrayController *)currentArrayController;

- (void)loadNoSelectionRecordHistory:(BOOL)recordHistory;

- (void)loadURL:(NSURL *)url recordHistory:(BOOL)recordHistory;
- (void)recordHistoryForURL:(NSURL *)url title:(NSString *)title;

- (void)setUpBackMenu;
- (void)setUpForwardMenu;

- (void)loadDocs;
- (void)loadDocIntoBrowser;
- (void)setUpForWebView:(WebView *)sender frame:(WebFrame *)frame;

- (void)reloadTableOfContents;

- (void)loadURL:(NSURL *)url recordHistory:(BOOL)recordHistory;

- (void)jumpToObject:(id)kvobject;

- (NSDictionary *)makeDictionaryFromManagedObject:(IGKDocRecordManagedObject *)mo transientObject:(IGKDocRecordManagedObject *)transientObject;

@end

@implementation IGKWindowController

@synthesize appDelegate;
@synthesize sideFilterPredicate;
@synthesize advancedFilterPredicate;
@synthesize selectedFilterDocset;
@synthesize shouldIndex;
@synthesize isInFullscreen;
@synthesize browserWebView;
@synthesize sideSearchQuery;

- (id)init
{
	if (self = [super init])
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indexedAllPaths:) name:@"IGKHasIndexedAllPaths" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSavingProgressSheet:) name:@"IGKWillSaveIndex" object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
		
		isInFullscreen = NO;
	}
	
	return self;
}

- (NSManagedObjectContext *)managedObjectContext
{
	return [[[NSApp delegate] valueForKey:@"kitController"] managedObjectContext];
}

- (void)backForwardManagerUpdatedLists:(id)bfm
{
	[self setUpBackMenu];
	[self setUpForwardMenu];
}

- (void)setUpBackMenu
{
	NSArray *backList = [backForwardManager backList];
	if (![backList count])
	{
		[backForwardButton setEnabled:NO forSegment:0];
		[backForwardButton setMenu:nil forSegment:0];
		return;
	}
	
	NSMenu *newBackMenu = [[NSMenu alloc] initWithTitle:@"Back"];
	for (WebHistoryItem *item in backList)
	{
		NSURL *url = [NSURL URLWithString:[item URLString]];
		//IGKDocRecordManagedObject *mo = [IGKDocRecordManagedObject resolveURL:url inContext:[self managedObjectContext] tableOfContentsMask:NULL];
		
		NSMenuItem *menuItem = [newBackMenu addItemWithTitle:[item title] action:@selector(backMenuItem:) keyEquivalent:@""];
		[menuItem setRepresentedObject:item];
		[menuItem setTarget:self];
		[menuItem setImage:[[self class] iconImageForURL:url]];
	}
	
	[backForwardButton setMenu:newBackMenu forSegment:0];
	
	[backForwardButton setEnabled:YES forSegment:0];
}
- (void)setUpForwardMenu
{
	NSArray *forwardList = [backForwardManager forwardList];
	if (![forwardList count])
	{
		[backForwardButton setEnabled:NO forSegment:1];
		[backForwardButton setMenu:nil forSegment:1];
		return;
	}
	
	NSMenu *newForwardMenu = [[NSMenu alloc] initWithTitle:@"Forward"];
	for (WebHistoryItem *item in forwardList)
	{
		NSURL *url = [NSURL URLWithString:[item URLString]];
		//IGKDocRecordManagedObject *mo = [IGKDocRecordManagedObject resolveURL:url inContext:[self managedObjectContext] tableOfContentsMask:NULL];
		
		NSMenuItem *menuItem = [newForwardMenu addItemWithTitle:[item title] action:@selector(forwardMenuItem:) keyEquivalent:@""];
		[menuItem setRepresentedObject:item];
		[menuItem setTarget:self];
		[menuItem setImage:[[self class] iconImageForURL:url]];
	}
	
	[backForwardButton setMenu:newForwardMenu forSegment:1];
	
	[backForwardButton setEnabled:YES forSegment:1];
}
+ (NSImage *)iconImageForURL:(NSURL *)url
{
	//Get an image for the item. We take this roundabout route to avoid resolving the URL (which is slow)
	NSString *extension = [[url lastPathComponent] pathExtension];
	BOOL isInstanceMethod = NO;
	if ([extension isEqual:@"instance-method"])
		isInstanceMethod = YES;
	
	NSString *entityName = [IGKDocRecordManagedObject entityNameFromURLComponentExtension:extension];
	CHSymbolButtonImageMask iconMask = [IGKDocRecordManagedObject iconMaskForEntity:entityName isInstanceMethod:isInstanceMethod];
	NSImage *image = [[CHSymbolButtonImage symbolImageWithMask:iconMask] objectAtIndex:0];
	
	return image;
}

- (void)backMenuItem:(NSMenuItem *)sender
{	
	NSInteger index = [[backForwardButton menuForSegment:0] indexOfItem:sender];
	NSInteger amount = index + 1;
	
	[backForwardManager goBackBy:amount];
}
- (void)forwardMenuItem:(NSMenuItem *)sender
{	
	NSInteger index = [[backForwardButton menuForSegment:1] indexOfItem:sender];
	NSInteger amount = index + 1;
	
	[backForwardManager goForwardBy:amount];
}

- (NSString *)windowNibName
{
	return @"CHDocumentationBrowser";
}

- (void)userDefaultsDidChange:(NSNotification *)notif
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IGKKeepOnAllSpaces"])
	{
		[[self window] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	}
	else
	{
		[[self window] setCollectionBehavior:NSWindowCollectionBehaviorDefault];
	}
}
- (void)windowDidLoad
{	
	currentModeIndex = CHDocumentationBrowserUIMode_NeedsSetup;
	[self setMode:CHDocumentationBrowserUIMode_TwoUp];
	sideSearchQuery = @"";
		
	//	[sideSearchIndicator startAnimation:self];
	
	sideSearchResults = [[NSMutableArray alloc] init];
	
	BOOL didIndex = YES;
	
	if (shouldIndex)
		[self startIndexing];
	else
	{
		didIndex = NO;
		[self loadNoSelectionRecordHistory:YES];
	}
	
	[backForwardButton setEnabled:NO forSegment:0];
	[backForwardButton setEnabled:NO forSegment:1];
	
	[searchViewTable setTarget:self];
	[searchViewTable setDoubleAction:@selector(advancedSearchDoubleAction:)];
	
	NSString *selectedFilterGroup = [[NSUserDefaults standardUserDefaults] valueForKey:@"IGKFilterGroup"];
	if ([selectedFilterGroup length])
		[rightFilterBarGroupByMenu selectItemWithTitle:selectedFilterGroup];
	
	sideSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil
													   ascending:YES
													  comparator:^NSComparisonResult (id obja, id objb)
	{
		NSString *a = [obja valueForKey:@"name"];
		NSString *b = [objb valueForKey:@"name"];
		
		//If a or b contain a (...) portion, then remove it for the purposes of comparison
		NSRange parenRange = [a rangeOfString:@"("];
		if (parenRange.location != NSNotFound)
			a = [a substringToIndex:parenRange.location];
		
		parenRange = [b rangeOfString:@"("];
		if (parenRange.location != NSNotFound)
			b = [b substringToIndex:parenRange.location];
		
		
		NSUInteger qLength = [sideSearchQuery length];
		NSString *qlower = [sideSearchQuery lowercaseString];
		NSUInteger qlowerLength = [qlower length];

		if (qLength == 0)
			return NSOrderedAscending;
		
		NSUInteger aLength = [a length];
		NSUInteger bLength = [b length];
		
		NSInteger l1 = abs(aLength - qLength);
		NSInteger l2 = abs(bLength - qLength);
		
		if (l1 == l2)
		{
			//If l1 == l2 then attempt to see if one of them equals or starts with the substring
			
			//Case sensitive equality
			if (aLength == qLength && [a isEqual:sideSearchQuery])
				return NSOrderedAscending;
			if (bLength == qLength && [b isEqual:sideSearchQuery])
				return NSOrderedDescending;
			
			//Case insensitive equality
			NSString *alower = [a lowercaseString];
			NSUInteger alowerLength = [alower length]; //We can't use aLength since alower may be a different length to a in some locales. Probably not an issue, since identifiers won't have unicode in them, but let's not risk the crash
			
			if (alowerLength == qlowerLength && [alower isEqual:sideSearchQuery])
				return NSOrderedAscending;

			NSString *blower = [a lowercaseString];
			NSUInteger blowerLength = [alower length];
			
			if (blowerLength == qlowerLength && [blower isEqual:sideSearchQuery])
				return NSOrderedAscending;
			
			//Case sensitive starts-with
			if (aLength > qLength && [[a substringToIndex:qLength] isEqual:sideSearchQuery])
				return NSOrderedAscending;
			if (bLength > qLength && [[b substringToIndex:qLength] isEqual:sideSearchQuery])
				return NSOrderedDescending;
			
			//Case insensitive start-with
			if (alowerLength > qlowerLength && [[alower substringToIndex:qlowerLength] isEqual:qlower])
				return NSOrderedAscending;
			if (blowerLength > qlowerLength && [[blower substringToIndex:qlowerLength] isEqual:qlower])
				return NSOrderedDescending;
			
			//So neither a nor b starts with q. Now we apply prioritization. Some types get priority over others. For instance, a class > method > typedef > constant
			NSUInteger objaPriority = [[obja valueForKey:@"priority"] shortValue];
			NSUInteger objbPriority = [[objb valueForKey:@"priority"] shortValue];
			
			//Higher priorities are better
			if (objaPriority > objbPriority)
				return NSOrderedAscending;
			else if (objaPriority < objbPriority)
				return NSOrderedDescending;
			
			//Just a normal compare
			return [a compare:b];
			
		}
		else if(l1 < l2)
			return NSOrderedAscending;
		
		return NSOrderedDescending;
		
	}];
	
	[sideSearchController setMaxRows:500];
	[sideSearchController setSmartSortDescriptors:[NSArray arrayWithObject:sideSortDescriptor]];
	
	[advancedController setSmartSortDescriptors:[NSArray arrayWithObject:sideSortDescriptor]];	
	
	if ([searchViewPredicateEditor numberOfRows] > 0)
		[searchViewPredicateEditor removeRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [searchViewPredicateEditor numberOfRows])] includeSubrows:YES];
	[searchViewPredicateEditor addRow:nil];
	
	[[browserWebView preferences] setDefaultFontSize:16];
	[[browserWebView preferences] setDefaultFixedFontSize:16];
	
	if (!didIndex)
	{
		[self didFinishIndexingOrLoading];
	}
	
	[self tableViewSelectionDidChange:nil];
	
	//Simulate user defaults changing
	[self userDefaultsDidChange:nil];
	
	[self setRightFilterBarShown:NO];
}
- (void)didFinishIndexingOrLoading
{	
	[docsetsController addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueObservingOptionNew context:NULL];
	//[self performSelector:@selector(didFinishIndexingOrLoadingDelayed) withObject:nil afterDelay:0.0];	
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"arrangedObjects"])
	{
		[self didFinishIndexingOrLoadingDelayed];
	}
}
- (void)didFinishIndexingOrLoadingDelayed
{
	NSString *selectedFilterDocsetPath = [[NSClassFromString(@"IGKPreferencesController") sharedPreferencesController] selectedFilterDocsetPath];
	if (selectedFilterDocsetPath)
	{
		for (id docset in [docsetsController arrangedObjects])
		{
			if ([[docset valueForKey:@"path"] isEqual:selectedFilterDocsetPath])
			{
				selectedFilterDocset = docset;
				
				for (NSMenuItem *m in [docsetsFilterPopupButton itemArray])
				{
					if ([m representedObject] == docset)
					{						
						[docsetsFilterPopupButton selectItem:m];
					}
				}
								
				break;
			}
		}
	}
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
			[twoPaneSplitView setEnabled:YES];
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
			[twoPaneSplitView setEnabled:YES];
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
		[sideSearchView setFrame:[twoPaneContentsTopView bounds]];
		[twoPaneContentsTopView addSubview:sideSearchView];
		
		//Table of contents
		//[tableOfContentsView setFrame:[[[twoPaneContentsSplitView subviews] objectAtIndex:1] bounds]];
		//[[[twoPaneContentsSplitView subviews] objectAtIndex:1] addSubview:tableOfContentsView];
		
		
		//Set up the search view
		[searchView setFrame:[contentView bounds]];
		
		
		// none -> two-up
		if (modeIndex == CHDocumentationBrowserUIMode_TwoUp || modeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
		{
			[contentView addSubview:twoPaneView];
			[twoPaneSplitView setEnabled:YES];
			
			// none -> browser
			if (modeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
			{
				CGFloat leftWidth = [twoPaneContentsTopView bounds].size.width;
				
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
	
	
	
	if (modeIndex == CHDocumentationBrowserUIMode_TwoUp)
	{
		[[sideSearchViewField window] makeFirstResponder:sideSearchViewField];
	}
	else if (modeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
	{
		if ([browserWebView window])
			[[browserWebView window] makeFirstResponder:browserWebView];
		else if ([noselectionView window])
			[[noselectionView window] makeFirstResponder:noselectionView];
		else
			[[self actualWindow] makeFirstResponder:[self actualWindow]];
	}
	else if (modeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
	{
		[self closeFindPanel:nil];
		
		[[searchViewField window] makeFirstResponder:searchViewField];
	}
}

- (IBAction)executeSearch:(id)sender
{
	[self executeSearchWithString:[sender stringValue]];
}

- (IBAction)focusSearchField:(id)sender
{
	if (currentModeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
		self.ui_currentModeIndex = [NSNumber numberWithInt:CHDocumentationBrowserUIMode_TwoUp];
	
	if (currentModeIndex == CHDocumentationBrowserUIMode_TwoUp)
		[[self actualWindow] makeFirstResponder:sideSearchViewField];
	else if (currentModeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
		[[self actualWindow] makeFirstResponder:searchViewField];
}
- (IBAction)changeViewModeTagged:(id)sender
{	
	NSInteger tag = [sender tag];
	if (tag == 0)
	{
		//We use self.ui_currentModeIndex instead of [self setMode:] because we want to refetch the side search view if we're already in advanced search
		self.ui_currentModeIndex = [NSNumber numberWithInt:CHDocumentationBrowserUIMode_BrowserOnly];
	}
	else if (tag == 1)
	{
		BOOL isSame = currentModeIndex == CHDocumentationBrowserUIMode_TwoUp;
		
		self.ui_currentModeIndex = [NSNumber numberWithInt:CHDocumentationBrowserUIMode_TwoUp];
		
		if (isSame)
			[[self actualWindow] makeFirstResponder:sideSearchViewField];
	}
	else if (tag == 2)
	{
		BOOL isSame = currentModeIndex == CHDocumentationBrowserUIMode_AdvancedSearch;
		
		self.ui_currentModeIndex = [NSNumber numberWithInt:CHDocumentationBrowserUIMode_AdvancedSearch];
		
		if (isSame)
			[[self actualWindow] makeFirstResponder:searchViewField];
	}
}

- (void)swipeWithEvent:(NSEvent *)event
{
	if (currentModeIndex != CHDocumentationBrowserUIMode_TwoUp &&
		currentModeIndex != CHDocumentationBrowserUIMode_AdvancedSearch)
		return;
	
	float dx = [event deltaX];
	float dy = [event deltaY];
	
	//Horizontal Swipe
	if (fabsf(dx) > fabsf(dy))
	{
		//Swipe left (positive is left and negative is right - go figure)
		if (dx > 0.0)
		{
			[backForwardManager goBack:nil];
		}
		//Swipe right
		else
		{
			[backForwardManager goForward:nil];
		}
	}
}
- (IBAction)backForward:(id)sender
{
	NSInteger selectedSegment = [sender selectedSegment];
	if(selectedSegment == 0)
		[backForwardManager goBack:nil];
	else if(selectedSegment == 1)
		[backForwardManager goForward:nil];
}

- (void)loadURLWithoutRecordingHistory:(NSURL *)url
{
	[self loadURL:url recordHistory:NO];
}
- (void)loadURLRecordHistory:(NSURL *)url
{
	[self loadURL:url recordHistory:YES];
}
- (void)loadURL:(NSURL *)url recordHistory:(BOOL)recordHistory
{
	[self loadURLRequest:[NSURLRequest requestWithURL:url] recordHistory:recordHistory];
}
- (void)loadURLRequest:(NSURLRequest *)urlRequest recordHistory:(BOOL)recordHistory
{
	NSURL *url = [urlRequest URL];
	
	isNonFilterBarType = YES;
	frecencyToken = 0;
	
	// set default title
	[[self actualWindow] setTitle:@"Documentation"];
	
	if ([[url scheme] isEqual:@"special"] && [[url resourceSpecifier] isEqual:@"no-selection"])
	{
		[browserWebView stopLoading:nil];
		[self loadNoSelectionRecordHistory:YES];
	}
	else if ([[url scheme] isEqual:@"ingr-doc"])
	{
		if ([[url path] containsString:@"headerfile"])
		{
			NSString *var = [[[[url pathComponents] igk_filter:^BOOL(id obj) {
				if ([obj containsString:@"headerfile"])
					return YES;
				return NO;
			}] igk_firstObject] stringByDeletingPathExtension];
			NSString *htmlFormat = @"<!doctype html><html><head><meta name='charset' content='utf-8'><title>Opening %@...</title><link rel='stylesheet' href='openingpage.css' type='text/css' media='screen' charset='utf-8'></head><body><div><h1>Opening <strong>%@...</strong></h1><p class='message'>Please wait while we load your file</p><p class='smallprint'>Orders are non-refundable. Do not ingest <code>%@</code>. We are not responsible for any damage incurred while reading <code>%@</code>. Contains brackets, semicolons and high fructose corn syrup. Designed in California. Made in China.</p></div></body></html>";
			NSString *html = [NSString stringWithFormat:htmlFormat, var, var, var, var];
			[[browserWebView mainFrame] loadHTMLString:html
											   baseURL:[[NSBundle mainBundle] resourceURL]];
		}
		else
		{		
			NSLog(@"Load URL = %@, record history = %d", url, recordHistory);
			NSManagedObjectContext *ctx = [[[NSApp delegate] valueForKey:@"kitController"] managedObjectContext];
			
			tableOfContentsMask = IGKHTMLDisplayType_None;
			IGKDocRecordManagedObject *result = [IGKDocRecordManagedObject resolveURL:url inContext:ctx tableOfContentsMask:&tableOfContentsMask];
					
			if (result)
			{
				[self setBrowserActive:YES];
				[self loadManagedObject:result tableOfContentsMask:tableOfContentsMask URL:url];
				if (recordHistory)
					[self recordHistoryForURL:url title:[result valueForKey:@"name"]];
			}
			
			[self reloadTableOfContents];
		}
	}
	else
	{
		[self loadNoSelectionRecordHistory:NO];
		[self setBrowserActive:YES];
		[browserWebView stopLoading:nil];
		[[browserWebView mainFrame] loadRequest:urlRequest];
	}
}
- (void)loadManagedObject:(IGKDocRecordManagedObject *)mo tableOfContentsMask:(IGKHTMLDisplayTypeMask)tm URL:(NSURL *)url
{
	frecencyToken = 0;
	currentObjectIDInBrowser = [mo objectID];
	
	IGKHTMLGenerator *generator = [[IGKHTMLGenerator alloc] init];
	[generator setContext:[[[NSApp delegate] valueForKey:@"kitController"] managedObjectContext]];
	[generator setManagedObject:mo];
	[generator setDisplayTypeMask:tm];
	
	acceptableDisplayTypes = [generator acceptableDisplayTypes];
	
	NSString *html = [generator html];
	
	//Load the HTML into the webview
	[[browserWebView mainFrame] loadHTMLString:html
									   baseURL:[[NSBundle mainBundle] resourceURL]];
	
	
	// set the window title to something proper...
	NSString *docsetName = [[mo valueForKey:@"docset"] localizedUserInterfaceName];
	NSString *objectName = [mo valueForKey:@"name"];
	NSString *parentName = [[mo valueForSoftKey:@"container"] valueForKey:@"name"];
	NSString *newTitle;
	if(parentName)
	{
		newTitle = [NSString stringWithFormat:@"%@ %C %@ %C %@", docsetName, 0x203A, parentName, 0x203A, objectName];
	}
	else {
		newTitle = [NSString stringWithFormat:@"%@ %C %@", docsetName, 0x203A, objectName];
	}
	
	[[self actualWindow] setTitle:newTitle];
	
	
	[self reloadRightFilterBarTable:mo transient:[generator transientObject]];
	
	[generator finish];
	
	
	//Find out if we're still here in 5 seconds
	
	if (url)
	{
		frecencyToken = random();
	
		NSArray *frecencyData = [NSArray arrayWithObjects:[NSNumber numberWithLong:frecencyToken], url, nil];
		[self performSelector:@selector(checkIfStillAlive:) withObject:frecencyData afterDelay:5.0];
	}
}
- (void)checkIfStillAlive:(NSArray *)frecencyData
{
	if ([[frecencyData objectAtIndex:0] longValue] == frecencyToken)
	{		
		//This was a triumph
		IGKFrecencyStore *frecencyStore = [IGKFrecencyStore storeWithIdentifier:@"net.fileability.ingredients.DocumentationArticleURLFrecency"];
		
		//I'm making a note here
		[frecencyStore recordItem:[[frecencyData objectAtIndex:1] absoluteString]];
	}
}

- (void)recordHistoryForURL:(NSURL *)url title:(NSString *)title
{
	WebHistoryItem *item = [[WebHistoryItem alloc] initWithURLString:[url absoluteString] title:title lastVisitedTimeInterval:[NSDate timeIntervalSinceReferenceDate]];
	[backForwardManager visitPage:item];
}


@dynamic ui_currentModeIndex;

- (void)setUi_currentModeIndex:(NSNumber *)n
{	
	CHDocumentationBrowserUIMode oldMode = currentModeIndex;
	CHDocumentationBrowserUIMode newMode = [n intValue];
	
	if (newMode == CHDocumentationBrowserUIMode_BrowserOnly || 
		newMode == CHDocumentationBrowserUIMode_TwoUp)
	{
		if (oldMode == CHDocumentationBrowserUIMode_AdvancedSearch)
		{
			
			if (newMode == CHDocumentationBrowserUIMode_TwoUp)
				[self restoreAdvancedSearchStateIntoTwoUp:NO];
			else
				[self restoreAdvancedSearchStateIntoTwoUp:NO];
		}
	}
	
	[self setMode:newMode];
		
	[self loadDocs];
}
- (NSNumber *)ui_currentModeIndex
{
	return [NSNumber numberWithInt:currentModeIndex];
}

- (void)executeSearchWithString:(NSString *)query
{
	if (currentModeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
		[self executeAdvancedSearch:query];
	else
		[self executeSideSearch:query];	
}

- (void)executeUISideSearch:(NSString *)query
{
	[[self actualWindow] makeFirstResponder:sideSearchViewField];
	[sideSearchViewField setStringValue:query];
	
	[[self actualWindow] makeKeyAndOrderFront:nil];
	[[self actualWindow] deminiaturize:nil]; 
	
	[self executeSideSearch:query];
}
- (void)executeSideSearch:(NSString *)query
{
	sideSearchQuery = query;
	
	if ([query length] > 0)
	{
		NSPredicate *fetchPredicate = nil;
		if (selectedFilterDocset)
			fetchPredicate = [NSPredicate predicateWithFormat:@"name CONTAINS[c] %@ && docset == %@", query, selectedFilterDocset];
		else
			fetchPredicate = [NSPredicate predicateWithFormat:@"name CONTAINS[c] %@", query];
		
		[sideSearchController setPredicate:fetchPredicate];
	}
	else
	{
		[sideSearchController setPredicate:[NSPredicate predicateWithValue:NO]];
	}
	
	sideSearchController.vipObject = nil;
	
	[sideSearchController refresh];
}
- (void)executeAdvancedSearch:(NSString *)query
{
	sideSearchQuery = query;
	
	NSPredicate *predicate = nil;
	NSMutableArray *subpredicates = [[NSMutableArray alloc] initWithCapacity:2];
	
	if ([query length] > 0)
	{
		if (selectedFilterDocset)
			predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[c] %@ && docset == %@", query, selectedFilterDocset];
		else
			predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[c] %@", query];
	}
	NSString *entityToFetch = [[NSString alloc] init];
	NSPredicate *predicateResults = [searchViewPredicateEditor predicateWithEntityNamed:&entityToFetch];

	if (predicateResults)
	{
		[subpredicates addObject:predicateResults];
	}
	if (predicate)
		[subpredicates addObject:predicate];
	
	
	[advancedController setEntityToFetch:entityToFetch];
	if ([subpredicates count])
		[advancedController setPredicate:[[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:subpredicates]];
	else
		[advancedController setPredicate:[NSPredicate predicateWithValue:NO]];
	
	
	[advancedController refresh];
}

- (void)startIndexing
{
	[self setRightFilterBarShown:NO];
	
	isIndexing = YES;
	
	wallpaperView = [[IGKSourceListWallpaperView alloc] initWithFrame:[[[twoPaneSplitView subviews] objectAtIndex:0] bounds]];
	[wallpaperView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[[[twoPaneSplitView subviews] objectAtIndex:0] addSubview:wallpaperView];
	
	[sideSearchViewField setEnabled:NO];
	[sideSearchViewField setEditable:NO];
	
	[self setBrowserActive:YES];
	
	NSRect topBarFrame = [browserTopbar frame];
	topBarFrame.origin.y += topBarFrame.size.height;
	[browserTopbar setFrame:topBarFrame];
	[browserTopbar setHidden:YES];
	
	NSRect browserViewFrame = [browserSplitViewContainer frame];
	browserViewFrame.size.height += topBarFrame.size.height;
	[browserSplitViewContainer setFrame:browserViewFrame];
	
	[twoPaneSplitView setColorIsEnabled:YES];
	[twoPaneSplitView setColor:[NSColor colorWithCalibratedRed:0.166 green:0.166 blue:0.166 alpha:1.000]];
	
	frecencyToken = 0;
	[[browserWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:
											 [NSURL fileURLWithPath:
											  [[NSBundle mainBundle] pathForResource:@"tictactoe" ofType:@"html"]
											  ]
											 ]];
	
	[self reloadTableOfContents];
}
- (void)showSavingProgressSheet:(NSNotification *)notif
{
	[savingProgressIndicator setUsesThreadedAnimation:YES];
	[savingProgressIndicator startAnimation:nil];
	[NSApp beginSheet:savingProgressWindow modalForWindow:[self actualWindow] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}
- (void)indexedAllPaths:(NSNotification *)notif
{
	[NSApp endSheet:savingProgressWindow];
	[savingProgressWindow orderOut:nil];
	[savingProgressIndicator stopAnimation:nil];
	
	[self stopIndexing];
}
- (void)stopIndexing
{
	isIndexing = NO;
	
	[wallpaperView removeFromSuperview];
	
	[sideSearchViewField setEnabled:YES];
	[sideSearchViewField setEditable:YES];
	
	[twoPaneSplitView setColor:[NSColor colorWithCalibratedRed:0.647 green:0.647 blue:0.647 alpha:1.000]];
	
	[docsetsController fetch:nil];
	
	[self didFinishIndexingOrLoading];
	
	//*** Show the top bar ***
	
	//Geometry for the top bar
	NSRect topBarFrame = [browserTopbar frame];
	topBarFrame.origin.y -= topBarFrame.size.height;
	[browserTopbar setHidden:NO];
	
	//Geometry for the browser container
	NSRect browserViewFrame = [browserSplitViewContainer frame];
	browserViewFrame.size.height -= topBarFrame.size.height;
	
	//Animate
	[NSAnimationContext beginGrouping];
	
	[[browserTopbar animator] setFrame:topBarFrame];
	[[browserSplitViewContainer animator] setFrame:browserViewFrame];
	
	[NSAnimationContext endGrouping];
	
	[browserWebView stringByEvaluatingJavaScriptFromString:@"completed();"];

	
	[[self actualWindow] makeFirstResponder:sideSearchViewField];
}

- (void)setAdvancedFilterPredicate:(NSPredicate *)pred
{
	advancedFilterPredicate = pred;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	if (control == sideSearchViewField)
	{
		if ([NSStringFromSelector(command) isEqual:@"moveUp:"])
		{
			[[self currentArrayController] selectPrevious:nil];
			return YES;
		}
		else if ([NSStringFromSelector(command) isEqual:@"moveDown:"])
		{
			[[self currentArrayController] selectNext:nil];
			return YES;
		}
		else if ([NSStringFromSelector(command) isEqual:@"insertNewline:"])
		{
			if ([self currentArrayController] == sideSearchController)
				[[browserWebView window] makeFirstResponder:browserWebView];
		}
		else if ([NSStringFromSelector(command) isEqual:@"cancelOperation:"])
		{
			
		}
	}
	else if (control == rightFilterBarSearchField)
	{
		if ([NSStringFromSelector(command) isEqual:@"moveUp:"] || [NSStringFromSelector(command) isEqual:@"moveDown:"])
		{
			[self performSelector:@selector(handleRightFilterBarEvent:) withObject:NSStringFromSelector(command) afterDelay:0.3];
			return YES;
		}
	}
	
	return NO;
}
- (void)handleRightFilterBarEvent:(NSString *)command
{
	if ([command isEqual:@"moveUp:"])
	{
		NSInteger i = [rightFilterBarTable selectedRow] - 1;
		while (i >= 0 && i < [rightFilterBarTable numberOfRows])
		{
			BOOL canSelect = [[rightFilterBarTable delegate] tableView:rightFilterBarTable shouldSelectRow:i];
			if (canSelect)
			{
				[rightFilterBarTable selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
				[rightFilterBarTable scrollRowToVisible:i];
				break;
			}
			
			i--;
		}
	}
	else if ([command isEqual:@"moveDown:"])
	{
		NSInteger i = [rightFilterBarTable selectedRow] + 1;
		while (i < [rightFilterBarTable numberOfRows] && i < [rightFilterBarTable numberOfRows])
		{
			BOOL canSelect = [[rightFilterBarTable delegate] tableView:rightFilterBarTable shouldSelectRow:i];
			if (canSelect)
			{
				[rightFilterBarTable selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
				[rightFilterBarTable scrollRowToVisible:i];
				break;
			}
			
			i++;
		}
	}
}

- (IBAction)changeSelectedFilterDocset:(id)sender
{
	selectedFilterDocset = [[sender selectedItem] representedObject];
	
	[[NSClassFromString(@"IGKPreferencesController") sharedPreferencesController] selectedFilterDocsetForPath:[selectedFilterDocset valueForKey:@"path"]];
	
	[self executeSearch:sideSearchViewField];
}

- (IBAction)predicateEditor:(id)sender
{	
	//Work out the new height of the rule editor
	NSUInteger numRows = [searchViewPredicateEditor numberOfRows];
	CGFloat height = numRows * [searchViewPredicateEditor rowHeight];
	
	NSView *superview = [searchViewPredicateEditorScrollView superview];
	CGFloat superviewHeight = [superview frame].size.height;
	
	const CGFloat maximumHeight = 200;
	if (height > maximumHeight)
		height = maximumHeight;
		
	NSRect predicateEditorRect = [searchViewPredicateEditorScrollView frame];
	predicateEditorRect.size.height = height;
	predicateEditorRect.origin.y = superviewHeight - height;
	
	NSRect tableRect = [searchViewTableScrollView frame];
	tableRect.size.height = superviewHeight - height;
	tableRect.origin.y = 0;
	
	[searchViewPredicateEditorScrollView setFrame:predicateEditorRect];
	[searchViewTableScrollView setFrame:tableRect];
	
	[self executeSearch:searchViewField];
}

- (IBAction)findSymbol:(id)sender
{
    //If the filter bar is hidden, show it
    [self setRightFilterBarShown:YES];
    
    //Focus the search field
    [[self actualWindow] makeFirstResponder:rightFilterBarSearchField];
}
- (IBAction)goToNextResult:(id)sender
{
	[[self currentArrayController] selectNext:nil];
}
- (IBAction)goToPreviousResult:(id)sender
{
	[[self currentArrayController] selectPrevious:nil];
}
- (IBAction)goToNextSymbol:(id)sender
{
	
}
- (IBAction)goToPreviousSymbol:(id)sender
{
	
}
- (IBAction)goToTableOfContentsSection:(NSMenuItem *)sender
{
	NSInteger tag = [sender tag];
	
	IGKHTMLDisplayType displayType = [[self class] tableOfContentsMenuItemToMask:tag];
	NSNumber *displayTypeNumber = [NSNumber numberWithInteger:displayType];
	
	if (![tableOfContentsTypes containsObject:displayTypeNumber])
		return;
	
	NSInteger index = [tableOfContentsTypes indexOfObject:displayTypeNumber];
	if (index < 0 || index == NSNotFound)
		return;
	
	if ([tableOfContentsPicker.selectedRowIndexes count] == 1 && [tableOfContentsPicker.selectedRowIndexes containsIndex:index])
		return;
	
	[tableOfContentsPicker.selectedRowIndexes removeAllIndexes];
	[tableOfContentsPicker.selectedRowIndexes addIndex:[tableOfContentsTypes indexOfObject:displayTypeNumber]];
	
	[self tableOfContentsChangedSelection];
	
	[tableOfContentsPicker setNeedsDisplay:YES];
}
+ (IGKHTMLDisplayTypeMask)tableOfContentsMenuItemToMask:(NSInteger)tag
{	
	if (tag == 1)
		return IGKHTMLDisplayType_All;
	else if (tag == 2)
		return IGKHTMLDisplayType_Overview;
	else if (tag == 3)
		return IGKHTMLDisplayType_Tasks;
	else if (tag == 4)
		return IGKHTMLDisplayType_Properties;
	else if (tag == 5)
		return IGKHTMLDisplayType_Methods;
	else if (tag == 6)
		return IGKHTMLDisplayType_Notifications;
	else if (tag == 7)
		return IGKHTMLDisplayType_Delegate;
	else if (tag == 8)
		return IGKHTMLDisplayType_BindingListings;
	else if (tag == 9)
		return IGKHTMLDisplayType_Misc;
	
	return IGKHTMLDisplayType_All;
}
+ (NSInteger)tableOfContentsMaskToMenuItem:(NSInteger)mask
{	
	if (mask == IGKHTMLDisplayType_All)
		return 1;
	else if (mask == IGKHTMLDisplayType_Overview)
		return 2;
	else if (mask == IGKHTMLDisplayType_Tasks)
		return 3;
	else if (mask == IGKHTMLDisplayType_Properties)
		return 4;
	else if (mask == IGKHTMLDisplayType_Methods)
		return 5;
	else if (mask == IGKHTMLDisplayType_Notifications)
		return 6;
	else if (mask == IGKHTMLDisplayType_Delegate)
		return 7;
	else if (mask == IGKHTMLDisplayType_BindingListings)
		return 8;
	else if (mask == IGKHTMLDisplayType_Misc)
		return 9;
	
	return 1;
}
- (NSWindow *)actualWindow
{
	if (isInFullscreen)
		return [contentView window];
	
	return [self window];
}

#pragma mark -
#pragma mark Table View Delegate 

- (void)setBrowserActive:(BOOL)active
{
	currentObjectIDInBrowser = nil;
	
	if (active)
	{
		id superview = [noselectionView superview];
		if (superview)
		{
			[noselectionView removeFromSuperview];
			[browserSplitViewContainer setFrame:[noselectionView frame]];
			[superview addSubview:browserSplitViewContainer];
		}
	}
	else
	{
		// set default title
		[[self actualWindow] setTitle:@"Documentation"];
		id superview = [browserSplitViewContainer superview];
		if (superview)
		{
			[browserSplitViewContainer removeFromSuperview];
			[noselectionView setFrame:[browserSplitViewContainer frame]];
			[superview addSubview:noselectionView];
		}
		
		[self closeFindPanel:nil];
	}
}

//Table of contents datasource
- (void)reloadTableOfContents
{
	tableOfContentsTypes = [[NSMutableArray alloc] init];
	tableOfContentsTitles = [[NSMutableArray alloc] init];
	
	[[tableOfContentsPicker selectedRowIndexes] removeAllIndexes];
	[[tableOfContentsPicker selectedRowIndexes] addIndex:0];
	
	IGKHTMLDisplayTypeMask m = acceptableDisplayTypes;
	
	if (IGKHTMLDisplayTypeMaskIsSingle(acceptableDisplayTypes))
	{
		//Hide the list
	}
	else
	{
		//Show the list
		
		IGKHTMLDisplayTypeMask displayTypeMask = acceptableDisplayTypes;
		if (displayTypeMask & IGKHTMLDisplayType_All)
			[self registerDisplayTypeInTableView:IGKHTMLDisplayType_All title:@"All"];
		
		if (displayTypeMask & IGKHTMLDisplayType_Overview)
			[self registerDisplayTypeInTableView:IGKHTMLDisplayType_Overview title:@"Overview"];
		if (displayTypeMask & IGKHTMLDisplayType_Properties)
			[self registerDisplayTypeInTableView:IGKHTMLDisplayType_Properties title:@"Properties"];
		if (displayTypeMask & IGKHTMLDisplayType_Methods)
			[self registerDisplayTypeInTableView:IGKHTMLDisplayType_Methods title:@"Methods"];
		if (displayTypeMask & IGKHTMLDisplayType_Notifications)
			[self registerDisplayTypeInTableView:IGKHTMLDisplayType_Notifications title:@"Notifications"];
		if (displayTypeMask & IGKHTMLDisplayType_Delegate)
			[self registerDisplayTypeInTableView:IGKHTMLDisplayType_Delegate title:@"Delegate"];
		if (displayTypeMask & IGKHTMLDisplayType_Misc)
			[self registerDisplayTypeInTableView:IGKHTMLDisplayType_Misc title:@"Misc"];
		if (displayTypeMask & IGKHTMLDisplayType_BindingListings)
			[self registerDisplayTypeInTableView:IGKHTMLDisplayType_BindingListings title:@"Bindings"];
	}
	
	
	
	[tableOfContentsTableView reloadData];
	[tableOfContentsPicker reloadData];
	
	
	
	if (IGKHTMLDisplayTypeMaskIsSingle(m))
	{
		NSRect newSideSearchContainerRect = [sideSearchContainer frame];
		newSideSearchContainerRect.origin.y = 0.0;
		newSideSearchContainerRect.size.height = [[sideSearchContainer superview] frame].size.height;
		
		NSRect newTableOfContentsRect = [tableOfContentsPicker frame];
		newTableOfContentsRect.origin.y = -newTableOfContentsRect.size.height;
		
		[NSAnimationContext beginGrouping];
		
		[sideSearchContainer setFrame:newSideSearchContainerRect];
		[tableOfContentsPicker setFrame:newTableOfContentsRect];
		
		[NSAnimationContext endGrouping];
	}
	else
	{
		CGFloat contentsHeight = [tableOfContentsPicker heightToFit];
		
		NSRect newSideSearchContainerRect = [sideSearchContainer frame];
		newSideSearchContainerRect.origin.y = contentsHeight;
		newSideSearchContainerRect.size.height = [[sideSearchContainer superview] frame].size.height - contentsHeight;
		
		NSRect newTableOfContentsRect = [tableOfContentsPicker frame];
		newTableOfContentsRect.origin.y = 0.0;
		newTableOfContentsRect.size.height = contentsHeight;
		
		[NSAnimationContext beginGrouping];
		
		[[sideSearchContainer animator] setFrame:newSideSearchContainerRect];
		[[tableOfContentsPicker animator] setFrame:newTableOfContentsRect];
		
		[NSAnimationContext endGrouping];
	}
}
- (void)registerDisplayTypeInTableView:(IGKHTMLDisplayType)type title:(NSString *)title
{
	[tableOfContentsTypes addObject:[NSNumber numberWithLongLong:type]];
	[tableOfContentsTitles addObject:title];
}
- (void)reloadRightFilterBarTable:(IGKDocRecordManagedObject *)mo transient:(IGKDocRecordManagedObject *)transientObject
{	
	[rightFilterBarSearchField setStringValue:@""];
	
	isNonFilterBarType = NO;
	
	if (![mo isKindOfEntityNamed:@"ObjCAbstractMethodContainer"])
	{
		isNonFilterBarType = YES;
		[self setRightFilterBarShown:NO];
		
		rightFilterBarTaskGroupedItems = [[NSMutableArray alloc] init];
		rightFilterBarNameGroupedItems = [[NSArray alloc] init];
		rightFilterBarKindGroupedItems = [[NSMutableArray alloc] init];
		rightFilterBarItems = [[NSMutableArray alloc] init];
		
		[rightFilterBarTable reloadData];
		
		return;
	}
	
	
	//*** Task grouped items ***
	rightFilterBarTaskGroupedItems = [[NSMutableArray alloc] init];
	
	NSSortDescriptor *positionIndexSort = [[NSSortDescriptor alloc] initWithKey:@"positionIndex" ascending:YES];
	NSArray *taskgroups = [[transientObject valueForSoftKey:@"taskgroups"] sortedArrayUsingDescriptors:[NSArray arrayWithObject:positionIndexSort]];
	
	for (NSManagedObject *taskgroup in taskgroups)
	{
		NSString *name = [taskgroup valueForKey:@"name"];
		if (![name length])
			continue;
		
		NSArray *taskitems = [[taskgroup valueForKey:@"items"] sortedArrayUsingDescriptors:[NSArray arrayWithObject:positionIndexSort]];
		
		if (![taskitems count])
			continue;
		
		[rightFilterBarTaskGroupedItems addObject:name];
		
		for (NSManagedObject *taskitem in taskitems)
		{
			NSMutableDictionary *taskitemDict = [[NSMutableDictionary alloc] init];
			
			/*
			 BOOL containsInDocument = [IGKHTMLGenerator containsInDocument:mo transientObject:transientObject displayTypeMask:acceptableDisplayTypes containerName:[transientObject valueForKey:@"name"] itemName:[mo valueForKey:@"name"] ingrcode:ingrcode];
			 
			 if (containsInDocument)
				[taskitemDict setValue:[NSString stringWithFormat:@"#%@.%@", [mo valueForKey:@"name"], ingrcode] forKey:@"href"];
			 else
				[taskitemDict setValue:[mo docURL:IGKHTMLDisplayType_All] forKey:@"href"];
			*/		 
			
			[taskitemDict setValue:[IGKHTMLGenerator hrefToActualFragment:taskitem transientObject:transientObject displayTypeMask:acceptableDisplayTypes]
							forKey:@"href"];
			
			NSString *taskitemHref = [taskitem valueForKey:@"href"];
			
			NSString *taskitemName = nil;
			NSString *applecode = [IGKHTMLGenerator extractApplecodeFromHref:taskitemHref itemName:&taskitemName];
			NSString *ingrcode = [IGKHTMLGenerator applecodeToIngrcode:applecode itemName:taskitemName];
			NSString *entityName = [IGKDocRecordManagedObject entityNameFromURLComponentExtension:ingrcode];
			CHSymbolButtonImageMask iconmask = [IGKDocRecordManagedObject iconMaskForEntity:entityName isInstanceMethod:[ingrcode isEqual:@"instance-method"]];
			
			[taskitemDict setValue:[NSNumber numberWithUnsignedLongLong:iconmask] forKey:@"iconMask"];
			[taskitemDict setValue:entityName forKey:@"entityName"];				
			[taskitemDict setValue:taskitemName forKey:@"name"];				
			
			[rightFilterBarTaskGroupedItems addObject:taskitemDict];
		}
	}
	
	
	//*** Name grouped items ***
	rightFilterBarKindGroupedItems = [[NSMutableArray alloc] init];
	
	NSSortDescriptor *nameSort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	
	NSSet *properties = [mo valueForSoftKey:@"properties"];
	
	if (properties)
	{
		NSArray *sortDescriptors = [NSArray arrayWithObject:nameSort];
		NSArray *sortedProperties = [properties sortedArrayUsingDescriptors:sortDescriptors];
		
		for (NSManagedObject *property in sortedProperties)
		{
			[rightFilterBarKindGroupedItems addObject:[self makeDictionaryFromManagedObject:property transientObject:transientObject]];
		}
	}
	
	NSSet *methods = [mo valueForSoftKey:@"methods"];
	if (methods)
	{		
		NSSortDescriptor *instanceMethodSort = [[NSSortDescriptor alloc] initWithKey:@"isInstanceMethod" ascending:YES];
		
		for (NSManagedObject *method in [methods sortedArrayUsingDescriptors:[NSArray arrayWithObjects:instanceMethodSort, nameSort, nil]])
		{
			[rightFilterBarKindGroupedItems addObject:[self makeDictionaryFromManagedObject:(IGKDocRecordManagedObject *)method transientObject:transientObject]];
		}
	}
	
	rightFilterBarNameGroupedItems = [rightFilterBarKindGroupedItems sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
		
		NSString *str1 = obj1;				
		if (![obj1 respondsToSelector:@selector(characterAtIndex:)])
			str1 = [obj1 valueForKey:@"name"];
		
		NSString *str2 = obj2;
		if (![obj2 respondsToSelector:@selector(characterAtIndex:)])
			str2 = [obj2 valueForKey:@"name"];
		
		return [str1 compare:str2];
	}];
	
	rightFilterBarItems = [[self currentFilterBarAllItems] mutableCopy];
	
	[rightFilterBarTable reloadData];
}
- (NSDictionary *)makeDictionaryFromManagedObject:(IGKDocRecordManagedObject *)mo transientObject:(IGKDocRecordManagedObject *)transientObject
{
	NSMutableDictionary *taskitemDict = [[NSMutableDictionary alloc] init];
	[taskitemDict setValue:[mo valueForKey:@"name"] forKey:@"name"];				
	[taskitemDict setValue:[[mo entity] name] forKey:@"entityName"];				
	
	NSString *ingrcode = [mo URLComponentExtension];
	BOOL containsInDocument = [IGKHTMLGenerator containsInDocument:mo transientObject:transientObject displayTypeMask:acceptableDisplayTypes containerName:[transientObject valueForKey:@"name"] itemName:[mo valueForKey:@"name"] ingrcode:ingrcode];
	
	if (containsInDocument)
		[taskitemDict setValue:[NSString stringWithFormat:@"#%@.%@", [mo valueForKey:@"name"], ingrcode] forKey:@"href"];
	else
		[taskitemDict setValue:[mo docURL:IGKHTMLDisplayType_All] forKey:@"href"];
	
	[taskitemDict setValue:[NSNumber numberWithUnsignedLongLong:[mo iconMask]] forKey:@"iconMask"];
	
	return taskitemDict;
}
- (IBAction)rightFilterGroupByMenu:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setValue:[sender titleOfSelectedItem] forKey:@"IGKFilterGroup"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[self rightFilterSearchField:rightFilterBarSearchField];
}
- (NSArray *)currentFilterBarAllItems
{
	CHDocumentationBrowserFilterGroupByMode groupBy = [[rightFilterBarGroupByMenu selectedItem] tag];
	if (groupBy == CHDocumentationBrowserFilterGroupByTasks)
	{
		return rightFilterBarTaskGroupedItems;
	}
	else if (groupBy == CHDocumentationBrowserFilterGroupByName)
	{			
		return rightFilterBarNameGroupedItems;
	}
	else if (groupBy == CHDocumentationBrowserFilterGroupByKind)
	{
		return rightFilterBarKindGroupedItems;
	}
	
	return nil;
}
- (IBAction)rightFilterSearchField:(id)sender
{
	//Filter rightFilterBarAllItems by name and put into rightFilterBarItems
	NSString *queryString = [sender stringValue];
	
	//If there's no query string, show all objects
	if (![queryString length])
	{
		[rightFilterBarItems setArray:[self currentFilterBarAllItems]];
		[rightFilterBarTable reloadData];
		
		return;
	}
	
	[rightFilterBarItems removeAllObjects];
	
	for (id obj in [self currentFilterBarAllItems])
	{
		//If it's an NSString
		if ([obj respondsToSelector:@selector(characterAtIndex:)])
		{
			//Check if the last object was a string
			if ([[rightFilterBarItems lastObject] respondsToSelector:@selector(characterAtIndex:)])
			{
				//If so, remove it
				[rightFilterBarItems removeLastObject];
			}
			
			//Add the new string
			[rightFilterBarItems addObject:obj];
			
			continue;
		}
		
		//Otherwise, add to the array if obj contains queryString
		if ([[obj valueForKey:@"name"] caseInsensitiveContainsString:queryString])
		{
			[rightFilterBarItems addObject:obj];
		}
	}
	
	//Check if the last object was a string
	if ([[rightFilterBarItems lastObject] respondsToSelector:@selector(characterAtIndex:)])
	{
		//If so, remove it
		[rightFilterBarItems removeLastObject];
	}
	
	[rightFilterBarTable reloadData];
	
	//Select the best matching item, as selected by smartSort:
	NSArray *smartSorted = [[rightFilterBarItems igk_filter:^(id obj) { return [obj respondsToSelector:@selector(keyEnumerator)]; }] smartSort:queryString];
	if ([smartSorted count])
	{
		NSUInteger smartIndex = [rightFilterBarItems indexOfObject:[smartSorted igk_firstObject]];
		if (smartIndex < NSNotFound && smartIndex > 0 && smartIndex < [rightFilterBarTable numberOfRows] && [[rightFilterBarTable delegate] tableView:rightFilterBarTable shouldSelectRow:smartIndex])
		{
			[rightFilterBarTable selectRowIndexes:[NSIndexSet indexSetWithIndex:smartIndex] byExtendingSelection:NO];
			[rightFilterBarTable scrollRowToVisible:smartIndex];
			[[rightFilterBarTable delegate] tableViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:rightFilterBarTable]];
		}
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == tableOfContentsTableView)
	{
		return [tableOfContentsTitles count];
	}
	else if (tableView == rightFilterBarTable)
	{
		return [rightFilterBarItems count];
	}
	
	return 0;
}

- (NSInteger)numberOfRowsInTableOfContents
{
	return [tableOfContentsTitles count];
}
- (id)valueForTableOfContentsColumn:(IGKTableOfContentsColumn)col row:(NSInteger)row
{
	id title = [tableOfContentsTitles objectAtIndex:row];
	
	if (col == IGKTableOfContentsTitleColumn)
	{
		return NSLocalizedString(title, @"");
	}
	
	if (col == IGKTableOfContentsIconColumn)
	{
		BOOL isSelected = [[tableOfContentsPicker selectedRowIndexes] containsIndex:row];
		NSString *imageName = [NSString stringWithFormat:@"ToC_%@%@", title, (isSelected ? @"_S" : [[self actualWindow] isMainWindow] ? @"" : @"_N")];
		return [NSImage imageNamed:imageName];
	}
	
	return nil;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView == tableOfContentsTableView)
	{
		id title = [tableOfContentsTitles objectAtIndex:row];
		
		if ([[tableColumn identifier] isEqual:@"title"])
		{
			return NSLocalizedString(title, @"");
		}
		
		if ([[tableColumn identifier] isEqual:@"icon"])
		{
			BOOL isSelected = [[tableView selectedRowIndexes] containsIndex:row];
			NSString *imageName = [NSString stringWithFormat:@"ToC_%@%@", title, (isSelected ? @"_S" : @"")];
			return [NSImage imageNamed:imageName];
		}
	}
	else if (tableView == rightFilterBarTable)
	{
		id item = [rightFilterBarItems objectAtIndex:row];
		
		if ([[tableColumn identifier] isEqual:@"name"])
		{
			if ([item respondsToSelector:@selector(characterAtIndex:)])
				return item;
			
			return [item valueForKey:@"name"];
		}
		
		if ([[tableColumn identifier] isEqual:@"normalIcon"])
		{
			BOOL isSelected = NO;//[[tableView selectedRowIndexes] containsIndex:row];

			if ([item respondsToSelector:@selector(objectForKey:)])
			{
				NSNumber *iconMask = [item objectForKey:@"iconMask"];
				CHSymbolButtonImageMask iconMaskC = [iconMask unsignedLongLongValue];
				NSArray *iconMaskImages = [CHSymbolButtonImage symbolImageWithMask:iconMaskC];
				
				return (isSelected ? [iconMaskImages objectAtIndex:1] : [iconMaskImages objectAtIndex:0]);
			}
		}
		
		return nil;
	}
	
	return nil;
}	

- (void)advancedSearchDoubleAction:(id)sender
{
	[self sideSearchTableChangedSelection];
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == tableOfContentsTableView)
	{
		[self tableOfContentsChangedSelection];
	}
	else if ([aNotification object] == sideSearchViewResults)
	{
		[self sideSearchTableChangedSelection];
	}
	else if ([aNotification object] == rightFilterBarTable)
	{
		[self rightFilterTableChangedSelection];
	}
}
- (BOOL)filterBarTableRowIsGroup:(NSInteger)row
{
	id currentRow = [rightFilterBarItems objectAtIndex:row];
	
	if ([currentRow respondsToSelector:@selector(characterAtIndex:)])
		return YES;
	
	return NO;
}
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView == rightFilterBarTable)
	{
		id currentRow = [rightFilterBarItems objectAtIndex:row];
		
		if ([currentRow respondsToSelector:@selector(characterAtIndex:)])
		{
			//[cell setAlignment:NSCenterTextAlignment];
			[cell setFont:[NSFont boldSystemFontOfSize:11.5]];//[NSFont fontWithName:@"Menlo-Bold" size:12]];
			if ([cell respondsToSelector:@selector(setTextColor:)])
				[cell setTextColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.80]];
			//[(NSCell *)cell setTag:10];
		}
		else
		{
			//[cell setAlignment:NSNaturalTextAlignment];
			[cell setFont:[NSFont fontWithName:@"Menlo" size:12]];
			//[(NSCell *)cell setTag:-2];
			//[cell setTag:-2];
			
			if ([cell respondsToSelector:@selector(setTextColor:)])
				[cell setTextColor:[NSColor blackColor]];
			
			if ([cell respondsToSelector:@selector(setHasStrikethrough:)])
				[(IGKStrikethroughTextCell *)cell setHasStrikethrough:[[currentRow valueForKey:@"isDeprecated"] boolValue]];
		}
	}
	else if (tableView == sideSearchViewResults)
	{
		if ([cell respondsToSelector:@selector(setHasStrikethrough:)])
		{
			id currentRow = [sideSearchController objectAtRow:row];
			[(IGKStrikethroughTextCell *)cell setHasStrikethrough:[[currentRow valueForKey:@"isDeprecated"] boolValue]];
		}
	}
	else if (tableView == searchViewTable)
	{
		if ([cell respondsToSelector:@selector(setHasStrikethrough:)])
		{
			id currentRow = [advancedController objectAtRow:row];
			[(IGKStrikethroughTextCell *)cell setHasStrikethrough:[[currentRow valueForKey:@"isDeprecated"] boolValue]];
		}
	}
}
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	if (tableView == rightFilterBarTable)
	{
		id currentRow = [rightFilterBarItems objectAtIndex:row];
		
		if ([currentRow respondsToSelector:@selector(characterAtIndex:)])
		{
			return NO;
		}
	}
	
	return YES;
}

- (IBAction)printAction:(id)sender
{
	NSPrintOperation *op = [NSPrintOperation
							printOperationWithView:[[[browserWebView mainFrame] frameView] documentView]
							printInfo:[NSPrintInfo sharedPrintInfo]];
	[op setShowsPrintPanel:YES];
	[op runOperation];
}

- (void)rightFilterTableChangedSelection
{
	NSInteger selind = [rightFilterBarTable selectedRow];
	if (selind == -1)
		return;

	id kvobject = [rightFilterBarItems objectAtIndex:selind];
	
	if ([kvobject respondsToSelector:@selector(objectForKey:)])
	{
		NSString *entityName = [kvobject valueForKey:@"entityName"];
		BOOL canJump = NO;
		if (tableOfContentsMask & IGKHTMLDisplayType_All)
			canJump = YES;
		else if (tableOfContentsMask & IGKHTMLDisplayType_None)
			canJump = NO;
		else if (tableOfContentsMask & IGKHTMLDisplayType_Overview)
			canJump = NO;
		else if (tableOfContentsMask & IGKHTMLDisplayType_Tasks)
			canJump = NO;
		else if (tableOfContentsMask & IGKHTMLDisplayType_Delegate)
			canJump = NO;
		else if ([entityName isEqual:@"ObjCMethod"] && (tableOfContentsMask & IGKHTMLDisplayType_Methods))
			canJump = YES;
		else if ([entityName isEqual:@"ObjCProperty"] && (tableOfContentsMask & IGKHTMLDisplayType_Properties))
			canJump = YES;
		else if ([entityName isEqual:@"ObjCNotification"] && (tableOfContentsMask & IGKHTMLDisplayType_Notifications))
			canJump = YES;
		else if ([entityName isEqual:@"ObjCBinding"] && (tableOfContentsMask & IGKHTMLDisplayType_BindingListings))
			canJump = YES;
		else if (tableOfContentsMask & IGKHTMLDisplayType_Misc)
			canJump = YES;
		
		if (!canJump)
		{
			/*
			if ([[kvobject valueForKey:@"href"] length] > 1)
			{
				NSURL *itemURL = [[self currentURL] URLByAppendingPathComponent:[[kvobject valueForKey:@"href"] substringFromIndex:1]];
				NSLog(@"itemURL = %@", itemURL);
				
				[self loadURL:itemURL recordHistory:YES];
				return;
			}
			*/
		}
	}
	
	[self jumpToObject:kvobject];
}
- (NSString *)currentURL
{
	//FIXME: Implement -currentURL
	return @"Hello World";
}
- (NSString *)currentDocsetIdentifier
{
	//FIXME: Implement -currentDocsetIdentifier
	return [NSString stringWithFormat:@"unknown/unknown"];
}
- (void)jumpToObject:(id)kvobject
{
	if ([kvobject respondsToSelector:@selector(characterAtIndex:)])
	{
		
	}
	else if ([kvobject isKindOfClass:[NSManagedObject class]])
	{
		//[browserWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.location.hash = '%@';", [kvobject URLComponent]]]
	}
	else
	{
		NSString *href = [kvobject valueForKey:@"href"];
				
		if ([href hasPrefix:@"#"])
		{
			[browserWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.location.hash = '%@';", href]];
		}
		else
		{
			[browserWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.location = '%@';", href]];
		}
	}
}

- (void)tableOfContentsChangedSelection
{
	[self loadDocIntoBrowser];
}
- (void)sideSearchTableChangedSelection
{
	//If we're indexing, don't change what page is displayed
	if (isIndexing)
		return;
	
	if ([self currentArrayController] == advancedController)
	{
		//We need to load our predicate into the side search controller
		[self restoreAdvancedSearchStateIntoTwoUp:YES];
		
		//Open in two up
		//TODO: Record a preference for whichever view this switched to. It could switch to either Two Up or Browser Only
		[self setMode:CHDocumentationBrowserUIMode_TwoUp];
	}
	
	//If there's no selection, switch to the no selection search page
	else if ([sideSearchController selection] == nil)
	{
		[self loadNoSelectionRecordHistory:YES];
		
		return;
	}
	
	//Otherwise switch to the webview
	[self setBrowserActive:YES];
	
	[self loadDocs];
}
- (void)loadNoSelectionRecordHistory:(BOOL)recordHistory
{
	currentObjectIDInBrowser = nil;
	acceptableDisplayTypes = 0;
	
	[self setBrowserActive:NO];
	[self reloadTableOfContents];
	
	if (recordHistory)
		[self recordHistoryForURL:[NSURL URLWithString:@"special:no-selection"] title:@"No Selection"];
}
- (void)loadDocs
{
	[self loadDocIntoBrowser];
	[self reloadTableOfContents];
}
- (void)restoreAdvancedSearchStateIntoTwoUp:(BOOL)selectSelected
{	
	//Restore the predicate, etc into the side search's array controlller
	[sideSearchController setPredicate:[advancedController predicate]];
	sideSearchController.vipObject = [advancedController selection];
	
	[sideSearchViewField setStringValue:[searchViewField stringValue]];
	
	if (selectSelected)
		[sideSearchController refreshAndSelectObject:[advancedController selection] renderSelection:NO];
	else
		[sideSearchController refreshAndSelectIndex:-1 renderSelection:NO];
}

- (IGKHTMLDisplayTypeMask)tableOfContentsSelectedDisplayTypeMask
{
	__block IGKHTMLDisplayTypeMask dtmask = IGKHTMLDisplayType_None;
	
	NSIndexSet *selectedIndicies = [tableOfContentsPicker selectedRowIndexes];
	[selectedIndicies enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
		
		//Get the mask at this selected index
		if (index >= [tableOfContentsTypes count])
			return;
		
		IGKHTMLDisplayType dt = [[tableOfContentsTypes objectAtIndex:index] longLongValue];
		
		//Append it to the bitmask 
		dtmask |= dt;
	}];
	
	//A display type of none is a little unhelpful - pass all along instead
	if (dtmask == IGKHTMLDisplayType_None)
		return IGKHTMLDisplayType_All;
	
	//Otherwise use the mask as-is
	return dtmask;
}
- (IGKArrayController *)currentArrayController
{
	if (currentModeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
		return advancedController;
	else
		return sideSearchController;
}
- (void)loadDocIntoBrowser
{	
	frecencyToken = 0;
	
	//Generate the HTML
	if (![[self currentArrayController] selection])
		return;
	
	NSManagedObject *currentSelectionObject = [[self currentArrayController] selection];
	BOOL objectSelectionHasNotChanged = (currentObjectIDInBrowser && [[currentSelectionObject objectID] isEqual:currentObjectIDInBrowser]);
	
	IGKHTMLDisplayTypeMask dtmask = [self tableOfContentsSelectedDisplayTypeMask];
	BOOL displayTypeSelectionHasNotChanged = (tableOfContentsMask && dtmask && tableOfContentsMask == dtmask);
	
	//If the object selection hasn't change AND the display type hasn't changed, then there's no need to do anything
	if (objectSelectionHasNotChanged && displayTypeSelectionHasNotChanged)
		return;
	
	
	
	tableOfContentsMask = dtmask;
	
	NSURL *url = [(IGKDocRecordManagedObject *)currentSelectionObject docURL:[self tableOfContentsSelectedDisplayTypeMask]];
	[self loadManagedObject:(IGKDocRecordManagedObject *)currentSelectionObject tableOfContentsMask:[self tableOfContentsSelectedDisplayTypeMask] URL:url];
	
	[self recordHistoryForURL:url title:[currentSelectionObject pageTitle:[self tableOfContentsSelectedDisplayTypeMask]]];
}

- (IBAction)openInSafari:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[[[[browserWebView mainFrame] dataSource] request] URL]];
}
- (IBAction)noselectionSearchField:(id)sender
{	
	NSString *url = nil;
	
	CFStringRef query = (CFStringRef)[noselectionSearchField stringValue];
	NSString *urlencodedQuery = NSMakeCollectable(CFURLCreateStringByAddingPercentEscapes(NULL, query, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8));
	
	if ([noselectionPopupButton selectedTag] == 0) // Google
	{
		url = [NSString stringWithFormat:@"http://www.google.com/search?q=%@", urlencodedQuery];
	}
	else if ([noselectionPopupButton selectedTag] == 1) // Cocoabuilder
	{
		url = [NSString stringWithFormat:@"http://www.cocoabuilder.com/archive/search/1?q=%@&l=cocoa", urlencodedQuery];
	}
	else if ([noselectionPopupButton selectedTag] == 2) // CocoaDev
	{
		url = [NSString stringWithFormat:@"http://www.google.com/search?q=site%%3Awww.cocoadev.com&q=%@", urlencodedQuery];
	}
	else if ([noselectionPopupButton selectedTag] == 3) // Stack Overflow
	{
		url = [NSString stringWithFormat:@"http://www.google.com/search?q=site%%3Astackoverflow.com&q=%@", urlencodedQuery];
	}
	
	if (!url)
		return;
	
	/*
	id superview = [noselectionView superview];
	if (superview)
	{
		[noselectionView removeFromSuperview];
		[browserSplitViewContainer setFrame:[noselectionView frame]];
		[superview addSubview:browserSplitViewContainer];
	}
	 */
	[self setBrowserActive:YES];
	
	[self loadURL:[NSURL URLWithString:@"about:blank"] recordHistory:NO];
	[self loadURL:[NSURL URLWithString:url] recordHistory:YES];
	//[[browserWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}

- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame
{
	NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:@"OK" alternateButton:@"" otherButton:@"" informativeTextWithFormat:@""];
	[alert beginSheetModalForWindow:[self actualWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}
- (BOOL)webView:(WebView *)sender runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame
{
	NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:@"OK" alternateButton:@"" otherButton:@"" informativeTextWithFormat:@""];
	NSInteger r = [alert runModal];
	
	if (r == NSAlertDefaultReturn)
		return YES;
	return NO;
}
/*
- (NSString *)webView:(WebView *)sender runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WebFrame *)frame;
{
	//FIXME: Implement JavaScript input() in webview
	return @"";
}
*/

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
	NSURL *url = [request URL];
	
	if ([[[[request URL] host] lowercaseString] isEqual:@"ingr-doc"])
	{
		if ([[url path] containsString:@"headerfile"])
		{
			NSLog(@"FOUND HEADER");
		}
		
		NSArray *comps = [[url path] pathComponents];
		if ([comps count] > 3)
		{
			NSArray *newcomps = [[NSArray arrayWithObject:@"/"] arrayByAddingObjectsFromArray:[comps subarrayWithRange:NSMakeRange(2, [comps count] - 2)]];
			NSURL *newURL = [[NSURL alloc] initWithScheme:@"ingr-doc" host:[comps objectAtIndex:1] path:[NSString pathWithComponents:newcomps]];
						
			[self performSelector:@selector(loadURLRecordHistory:) withObject:newURL afterDelay:0.0];
			return nil;
		}
	}
	else if ([[[[request URL] host] lowercaseString] isEqual:@"ingr-link"])
	{
		NSArray *comps = [[url path] pathComponents];
		if ([comps count] == 2)
		{
			NSString *term = [comps objectAtIndex:1];
						
			NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
			[fetch setPredicate:[NSPredicate predicateWithFormat:@"name=%@", term]];
			[fetch setEntity:[NSEntityDescription entityForName:@"DocRecord" inManagedObjectContext:[self managedObjectContext]]];
			
			NSArray *items = [[self managedObjectContext] executeFetchRequest:fetch error:nil];
			for (id item in items)
			{
				[self performSelector:@selector(loadURLRecordHistory:) withObject:[item docURL:IGKHTMLDisplayType_All] afterDelay:0.0];
				break;
			}
			
			/*
			for (id kvobject in rightFilterBarKindGroupedItems)
			{
				if ([[kvobject valueForKey:@"name"] isEqual:term])
				{
					NSString *url = [NSString stringWithFormat:@"ingr-doc://%@/%@"];
					[self performSelector:@selector(loadURLRecordHistory:) withObject:newURL afterDelay:0.0];
				}
			}
			 */
		}
		
		return nil;
	}
	
	return request;
}
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
	[self setUpForWebView:sender frame:frame];
}
- (void)webView:(WebView *)sender didReceiveServerRedirectForProvisionalLoadForFrame:(WebFrame *)frame
{
	[self setUpForWebView:sender frame:frame];
}
- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame
{
	[self setUpForWebView:sender frame:frame];
}
- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
	if (![[[[frame dataSource] request] URL] isEqual:[NSURL URLWithString:@"about:blank"]])
		[self recordHistoryForURL:[[[frame dataSource] request] URL] title:title];
	
	[self setUpForWebView:sender frame:frame];
	
	if ([title length]) [[self actualWindow] setTitle:title];
}
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	[self setUpForWebView:sender frame:frame];
}
- (void)setUpForWebView:(WebView *)sender frame:(WebFrame *)frame
{
	if (sender != browserWebView || frame != [browserWebView mainFrame])
		return;
	
	//[self setBrowserActive:YES];
	
	BOOL rightFilterBarIsShown = NO;
	
	NSURL *url = [[[frame dataSource] request] URL];
	if (!url || [[url scheme] isEqual:@"file"])
	{
		[urlField setStringValue:@""];
		
		NSRect r = [browserToolbar frame];
		[browserToolbar setFrame:NSMakeRect(0, -r.size.height, r.size.width, r.size.height)];

		NSRect r2 = [browserWebViewContainer frame];
		[browserWebView setFrame:NSMakeRect(0, 0, r2.size.width, r2.size.height/* - [browserTopbar frame].size.height*/)];
		
		NSURL *mainURL = [[[frame dataSource] request] mainDocumentURL];
		if ([[mainURL lastPathComponent] isEqual:@"Resources"])
		{
			if (![[NSUserDefaults standardUserDefaults] boolForKey:@"IGKRightFilterBarIsHidden"])
			{
				rightFilterBarIsShown = YES;
			}
		}
	}
	else
	{
		[urlField setStringValue:[url absoluteString]];
		
		NSRect r = [browserToolbar frame];
		[browserToolbar setFrame:NSMakeRect(0, 0, r.size.width, r.size.height)];
		
		NSRect r2 = [browserWebViewContainer frame];
		[browserWebView setFrame:NSMakeRect(0, r.size.height, r2.size.width, r2.size.height - r.size.height/* - [browserTopbar frame].size.height*/)];
	}
	
	
	//Hide or show the filter bar, but only if the user hasn't explicitly hidden it
	BOOL userHasHiddenRightFilterBar = [[NSUserDefaults standardUserDefaults] boolForKey:@"rightFilterBarIsHidden"];
	
	if (userHasHiddenRightFilterBar || isNonFilterBarType)
		[self setRightFilterBarShown:NO];
	else
		[self setRightFilterBarShown:rightFilterBarIsShown];
}
- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
	IGKWindowController *newController = [[[NSApp delegate] kitController] newWindowIsIndexing:NO];
	[newController loadURLRequest:request recordHistory:YES];
	
	return [newController browserWebView];
}

- (IBAction)toggleRightFilterBar:(id)sender
{
	BOOL shown = ![self rightFilterBarShown];
	
	if ([self isInValidStateForRightFilterBar])
		[self setRightFilterBarShown:shown];
	
	[[NSUserDefaults standardUserDefaults] setBool:!shown forKey:@"rightFilterBarIsHidden"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}
- (BOOL)rightFilterBarShown
{
	return ([rightFilterBarView superview] != nil);
}
- (void)setRightFilterBarShown:(BOOL)shown
{
	NSView *sideview = [[browserSplitView subviews] objectAtIndex:1];
	
	if (shown)
	{
		
		NSRect r = [browserSplitView frame];
		r.size.width = [[browserSplitView superview] frame].size.width;
		[browserSplitView setFrame:r];
		[browserSplitView setEnabled:YES];
		
		if (![rightFilterBarView superview])
		{
			[rightFilterBarView setFrame:[sideview bounds]];
			[sideview addSubview:rightFilterBarView];
		}
	}
	else
	{
		NSRect r = [browserSplitView frame];
		r.size.width = [[browserSplitView superview] frame].size.width + [[[browserSplitView subviews] objectAtIndex:1] frame].size.width + 1;// + [browserSplitView dividerThickness];
		[browserSplitView setFrame:r];
		[browserSplitView setEnabled:NO];
		
		if ([rightFilterBarView superview])
		{
			[rightFilterBarView removeFromSuperview];
		}
	}
}

- (IBAction)toggleFullscreen:(id)sender
{
	NSMutableDictionary *fsOptions = [[NSMutableDictionary alloc] init];
	NSInteger presentationOptions = (NSApplicationPresentationAutoHideDock|NSApplicationPresentationAutoHideMenuBar);
	[fsOptions setObject:[NSNumber numberWithInt:presentationOptions] forKey:NSFullScreenModeApplicationPresentationOptions];
	[fsOptions setObject:[NSNumber numberWithBool:NO] forKey:NSFullScreenModeAllScreens];
	
	if (isInFullscreen)
	{
		isInFullscreen = NO;
		
		[[[NSApp delegate] kitController] setFullscreenWindowController:nil];
		[[[super window] contentView] exitFullScreenModeWithOptions:fsOptions];
		[[super window] makeKeyAndOrderFront:sender];
	}
	else 
	{
		if (![[[NSApp delegate] kitController] fullscreenWindowController])
		{
			isInFullscreen = YES;

			[[[NSApp delegate] kitController] setFullscreenWindowController:self];
			[[[super window] contentView] enterFullScreenMode:[[self window] screen] 
											 withOptions:fsOptions];
			[[super window] orderOut:sender];
		}
		else
		{
			// noooooooooo!
			return;
		}
	}
}


#pragma mark Search Timeout

- (void)arrayControllerTimedOut:(IGKArrayController *)ac
{
	if (ac == sideSearchController)
		[sideSearchIndicator startAnimation:nil];
}
- (void)arrayControllerFinishedSearching:(IGKArrayController *)ac
{
	if (ac == sideSearchController)
		[sideSearchIndicator stopAnimation:nil];
}

#pragma mark Find

- (void)windowDidResize:(NSNotification *)notification
{
	[self relayoutFindPanel];
}
- (void)viewResized:(id)resizedView
{
	[self relayoutFindPanel];
}

- (IBAction)doFindPanelAction:(id)sender
{
	if (![self isInValidStateForFindPanel])
		return;
	
	[self relayoutFindPanel];
	
	[[self actualWindow] addChildWindow:findWindow ordered:NSWindowAbove];
	[findWindow setParentWindow:[self actualWindow]];
	[[[[findWindow contentView] subviews] lastObject] viewDidMoveToParentWindow:[self actualWindow]];
	[findWindow makeKeyAndOrderFront:nil];
	
	if (!isInFullscreen)
		[[self actualWindow] makeMainWindow];
}
- (IBAction)closeFindPanel:(id)sender
{
	[[self actualWindow] removeChildWindow:findWindow];
	[findWindow close];
}

- (IBAction)findPanelSearchField:(id)sender
{
	[self findPanelNext:sender];
}
- (IBAction)findPanelSegmentedControl:(id)sender
{
	if ([sender selectedSegment] == 1)
	{
		[self findPanelNext:sender];
	}
	else
	{
		[self findPanelPrevious:sender];
	}
}
- (IBAction)findPanelPrevious:(id)sender
{
	if (![self isInValidStateForFindPanel])
		return;
	
	[browserWebView searchFor:[findSearchField stringValue] direction:NO caseSensitive:NO wrap:YES];
}
- (IBAction)findPanelNext:(id)sender
{
	if (![self isInValidStateForFindPanel])
		return;
	
	[browserWebView searchFor:[findSearchField stringValue] direction:YES caseSensitive:NO wrap:YES];
}

- (BOOL)isInValidStateForFindPanel
{
	if (![browserWebView window])
	{
		[self closeFindPanel:self];
		return NO;
	}
	if (currentModeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
	{
		[self closeFindPanel:self];
		return NO;
	}
	
	return YES;
}
- (BOOL)isInValidStateForRightFilterBar
{
	if (![browserWebView window] || isNonFilterBarType || currentModeIndex == CHDocumentationBrowserUIMode_AdvancedSearch)
	{
		[self setRightFilterBarShown:NO];
		return NO;
	}
	
	return YES;
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    SEL action = [anItem action];
    
	if (action == @selector(doFindPanelAction:) || action == @selector(findPanelNext:) || action == @selector(findPanelPrevious:))
		return [self isInValidStateForFindPanel];
	
	if (action == @selector(changeViewModeTagged:))
	{
		if ([anItem tag] == 0 && currentModeIndex == CHDocumentationBrowserUIMode_BrowserOnly)
			return NO;
		return YES;
	}
	
	if (action == @selector(toggleRightFilterBar:) || action == @selector(findSymbol:))
	{
	    if (action == @selector(toggleRightFilterBar:))
	    {
            NSString *verb = [self rightFilterBarShown] ? @"Hide" : @"Show";
            [anItem setTitle:[NSString stringWithFormat:@"%@ Filter Bar", verb]];
	    }
	    
	    return [self isInValidStateForRightFilterBar];
	}
	
	if (action == @selector(goToPreviousResult:))
		return [[self currentArrayController] canSelectPrevious];
    if (action == @selector(goToNextResult:))
		return [[self currentArrayController] canSelectNext];
	
	if (action == @selector(toggleFullscreen:))
	{
		if (!isInFullscreen && [[[NSApp delegate] kitController] fullscreenWindowController])
			return NO;
	}
	
	if (action == @selector(goToTableOfContentsSection:))
	{
		NSInteger tag = [anItem tag];
		
		IGKHTMLDisplayType displayType = [[self class] tableOfContentsMenuItemToMask:tag];
		NSNumber *displayTypeNumber = [NSNumber numberWithInteger:displayType];
		
		NSInteger index = [tableOfContentsTypes indexOfObject:displayTypeNumber];
		if (index < 0 || index == NSNotFound)
			return NO;
		
		if ([tableOfContentsPicker.selectedRowIndexes count] == 1 && [tableOfContentsPicker.selectedRowIndexes containsIndex:index])
			return NO;
	}
	
	return YES;
}

- (void)relayoutFindPanel
{
	if (![self isInValidStateForFindPanel])
		return;
	
	NSRect newFindViewFrame = [findView frame];
	newFindViewFrame.origin.y = [browserWebViewContainer frame].size.height - newFindViewFrame.size.height + 1;
	newFindViewFrame.origin.x = [browserWebViewContainer frame].size.width - newFindViewFrame.size.width - 20.0 - 15.0;
	
	NSRect webViewConvertedFrame = [browserWebView convertRect:[browserWebView bounds] toView:[[self actualWindow] contentView]];
	
	NSRect newFrame = [findWindow frame];
	newFrame.origin = [[self actualWindow] frame].origin;
	newFrame.origin.y += [browserWebViewContainer frame].size.height - newFrame.size.height + 1;
	newFrame.origin.x += NSMaxX(webViewConvertedFrame) - 20.0 - 15.0 - newFindViewFrame.size.width; //[browserWebViewContainer frame].size.width - newFindViewFrame.size.width - 20.0 - 15.0 + [[self actualWindow] frame].size.width - [browserSplitView frame].size.width;
	
	NSRect stepperFrame = [findBackForwardStepper frame];
	stepperFrame.size.height = 20.0;
	[findBackForwardStepper setFrame:stepperFrame];
	
	[findWindow setFrame:newFrame display:YES];
}

@end
