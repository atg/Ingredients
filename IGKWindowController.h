//
//  IGKWindowController.h
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Written in 2010 by Fileability.
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
	
	IBOutlet NSView *browserSplitViewContainer;
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
	BOOL isNonFilterBarType;
	
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
	IBOutlet NSView *sideSearchIndicator;
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
	
	
	//*** In-file Find ***
	IBOutlet NSWindow *findWindow;
	IBOutlet NSView *findView;
	IBOutlet NSTextField *findSearchField;
	IBOutlet NSButton *findCloseButton;
	IBOutlet NSButton *findRegexToggle;
	IBOutlet NSSegmentedControl *findBackForwardStepper;
	
	
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
	BOOL isInFullscreen;
	
	long frecencyToken;
	
	NSManagedObjectID *currentObjectIDInBrowser;
	
	NSArray *selectedFilterDocset;
}

@property (assign) IGKApplicationDelegate *appDelegate;
@property (assign) NSPredicate *sideFilterPredicate;
@property (assign) NSPredicate *advancedFilterPredicate;

@property (assign) NSNumber *ui_currentModeIndex;

@property (assign) BOOL shouldIndex;
@property (assign) BOOL isInFullscreen;

@property (assign) NSArray *selectedFilterDocset;

@property (readonly) WebView *browserWebView;

@property (readonly) NSString *sideSearchQuery;

+ (NSImage *)iconImageForURL:(NSURL *)url;
+ (IGKHTMLDisplayTypeMask)tableOfContentsMenuItemToMask:(NSInteger)tag;

- (IBAction)noselectionSearchField:(id)sender;

- (IBAction)changeSelectedFilterDocset:(id)sender;

- (IBAction)rightFilterSearchField:(id)sender;
- (IBAction)rightFilterGroupByMenu:(id)sender;

- (void)executeUISideSearch:(NSString *)query;
- (IBAction)executeSearch:(id)sender;
- (IBAction)executeAdvancedSearch:(id)sender;

- (IBAction)focusSearchField:(id)sender;
- (IBAction)changeViewModeTagged:(id)sender;
- (IBAction)backForward:(id)sender;

- (IBAction)openInSafari:(id)sender;

- (void)executeSearchWithString:(NSString *)query;
- (void)setBrowserActive:(BOOL)active;

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

//Right filter bar
- (IBAction)findSymbol:(id)sender;

- (IBAction)toggleRightFilterBar:(id)sender;
- (BOOL)rightFilterBarShown;
- (void)setRightFilterBarShown:(BOOL)shown;


- (IBAction)toggleFullScreen:(id)sender;

- (BOOL)filterBarTableRowIsGroup:(NSInteger)row;

- (IBAction)predicateEditor:(id)sender;

- (void)loadURLRequest:(NSURL *)urlRequest recordHistory:(BOOL)recordHistory;

//Find Panel
- (IBAction)closeFindPanel:(id)sender;
- (IBAction)findPanelSearchField:(id)sender;
- (IBAction)findPanelSegmentedControl:(id)sender;
- (IBAction)findPanelPrevious:(id)sender;
- (IBAction)findPanelNext:(id)sender;

//Go to...
- (IBAction)goToNextResult:(id)sender;
- (IBAction)goToPreviousResult:(id)sender;
- (IBAction)goToNextSymbol:(id)sender;
- (IBAction)goToPreviousSymbol:(id)sender;
- (IBAction)goToTableOfContentsSection:(NSMenuItem *)sender;

@end
