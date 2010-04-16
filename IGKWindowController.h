//
//  IGKWindowController.h
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "IGKHTMLGenerator.h"
#import "IGKTableOfContentsView.h"

@class BWSplitView;
@class IGKApplicationDelegate;
@class IGKSourceListWallpaperView;
@class IGKArrayController;
@class IGKBackForwardManager;
@class IGKPredicateEditor;

typedef enum {
	
	CHDocumentationBrowserUIMode_BrowserOnly = 0,
	CHDocumentationBrowserUIMode_TwoUp = 1,
	CHDocumentationBrowserUIMode_AdvancedSearch = 2,
	
	CHDocumentationBrowserUIMode_NeedsSetup = 20
	
} CHDocumentationBrowserUIMode;

typedef enum {
	CHDocumentationBrowserFilterGroupByTasks = 0,
	CHDocumentationBrowserFilterGroupByName = 1,
	CHDocumentationBrowserFilterGroupByKind = 2
} CHDocumentationBrowserFilterGroupByMode;

@interface IGKWindowController : NSWindowController<IGKTableOfContentsDelegate>
{
	IGKApplicationDelegate *appDelegate;
	
	
	//*** Basic Structure ***
	IBOutlet NSView *contentView;
	
	IBOutlet NSView *twoPaneView;
	IBOutlet BWSplitView *twoPaneSplitView;
	//IBOutlet BWSplitView *twoPaneContentsSplitView;
	IBOutlet NSView *twoPaneContentsTopView;
	
	
	//*** Browser View ***
	IBOutlet NSSegmentedControl *backForwardButton;
	IBOutlet IGKBackForwardManager *backForwardManager;
	
	IBOutlet NSSplitView *browserSplitView;
	
	IBOutlet NSView *browserView;
	IBOutlet NSTextField *browserViewTitle;
	IBOutlet NSTextField *browserViewPath;
	IBOutlet NSView *browserWebViewContainer;
	
	IBOutlet WebView *browserWebView;
	IBOutlet NSTextField *urlField;
	IBOutlet NSView *browserTopbar;
	IBOutlet NSView *browserToolbar;
	
	//*** Filter Bar ***
	NSMutableArray *rightFilterBarTaskGroupedItems;
	NSArray *rightFilterBarNameGroupedItems;
	NSMutableArray *rightFilterBarKindGroupedItems;
	
	NSMutableArray *rightFilterBarItems;
	IBOutlet NSView *rightFilterBarView;
	IBOutlet NSSearchField *rightFilterBarSearchField;
	IBOutlet NSPopUpButton *rightFilterBarGroupByMenu;
	IBOutlet NSTableView *rightFilterBarTable;
	
	
	//*** No Selection ***
	IBOutlet NSView *noselectionView;
	IBOutlet NSPopUpButton *noselectionPopupButton;
	IBOutlet NSTextField *noselectionSearchField;
	
	IGKHTMLDisplayTypeMask acceptableDisplayTypes;
	
	
	//*** Side Search ***
	IBOutlet IGKArrayController *sideSearchController;
	
	IBOutlet NSView *sideSearchContainer;
	
	IBOutlet NSView *sideSearchView;
	IBOutlet NSSearchField *sideSearchViewField;
	IBOutlet NSTableView *sideSearchViewResults;
	
	NSMutableArray *sideSearchResults;
	NSPredicate *sideFilterPredicate;
	NSSortDescriptor *sideSortDescriptor;
	NSString *sideSearchQuery;
	
	
	//*** Table of Contents ***
	IBOutlet NSView *tableOfContentsView;
	IBOutlet NSTableView *tableOfContentsTableView;
	IBOutlet IGKTableOfContentsView *tableOfContentsPicker;
	
	NSUInteger tableOfContentsMask;
	NSMutableArray *tableOfContentsTypes;
	NSMutableArray *tableOfContentsTitles;
	
	
	//*** Advanced Search ***
	IBOutlet IGKArrayController *advancedController;
	
	IBOutlet NSView *searchView;
	IBOutlet NSSearchField *searchViewField;
	IBOutlet NSScrollView *searchViewPredicateEditorScrollView;
	IBOutlet IGKPredicateEditor *searchViewPredicateEditor;
	IBOutlet NSScrollView *searchViewTableScrollView;
	IBOutlet NSTableView *searchViewTable;
	
	NSPredicate *advancedFilterPredicate;
	
	
	//*** Other ***
	IBOutlet NSWindow *savingProgressWindow;
	IBOutlet NSProgressIndicator *savingProgressIndicator;
	IGKSourceListWallpaperView *wallpaperView;
	
	IBOutlet NSPopUpButton *docsetsFilterPopupButton;
	IBOutlet NSArrayController *docsetsController;
	
	int currentModeIndex;
	
	BOOL awaken;
	BOOL shouldIndex;
	BOOL isIndexing;
	
	NSManagedObjectID *currentObjectIDInBrowser;
	
	NSArray *selectedFilterDocset;
}

@property (assign) IGKApplicationDelegate *appDelegate;
@property (assign) NSPredicate *sideFilterPredicate;
@property (assign) NSPredicate *advancedFilterPredicate;

@property (assign) NSNumber *ui_currentModeIndex;

@property (assign) BOOL shouldIndex;

@property (assign) NSArray *selectedFilterDocset;

- (IBAction)noselectionSearchField:(id)sender;

- (IBAction)changeSelectedFilterDocset:(id)sender;

- (IBAction)rightFilterSearchField:(id)sender;
- (IBAction)rightFilterGroupByMenu:(id)sender;

- (IBAction)executeSearch:(id)sender;
- (IBAction)executeAdvancedSearch:(id)sender;
- (IBAction)changeViewModeTagged:(id)sender;
- (IBAction)backForward:(id)sender;

- (IBAction)openInSafari:(id)sender;

- (void)setBrowserActive:(BOOL)active;

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

- (IBAction)toggleRightFilterBar:(id)sender;
- (BOOL)rightFilterBarShown;
- (void)setRightFilterBarShown:(BOOL)shown;

@end
