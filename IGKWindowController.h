//
//  IGKWindowController.h
//  Ingredients
//
//  Created by Alex Gordon on 23/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class IGKApplicationDelegate;
@class IGKSourceListWallpaperView;
@class IGKArrayController;

typedef enum {
	
	CHDocumentationBrowserUIMode_BrowserOnly=0,
	CHDocumentationBrowserUIMode_TwoUp=1,
	CHDocumentationBrowserUIMode_AdvancedSearch=2,
	
	CHDocumentationBrowserUIMode_NeedsSetup=20
	
} CHDocumentationBrowserUIMode;

typedef enum {
	CHDocsetFilterShowAll=0,
	CHDocsetFilterShowMac=1,
	CHDocsetFilterShowiPhone=2,
	CHDocsetFilterShowiPad=3
} CHDocsetFilterMode;

@interface IGKWindowController : NSWindowController
{
	IGKApplicationDelegate *appDelegate;
	
	
	//Basic Structure
	IBOutlet NSWindow *window;
	IBOutlet NSView *contentView;
	
	IBOutlet NSView *twoPaneView;
	IBOutlet NSSplitView *twoPaneSplitView;
	IBOutlet NSSplitView *twoPaneContentsSplitView;
	
	//Browser View
	IBOutlet NSView *browserView;
	IBOutlet NSTextField *browserViewTitle;
	IBOutlet NSTextField *browserViewPath;
	IBOutlet NSView *browserWebViewContainer;
	IBOutlet WebView *browserWebView;
	
	//Side Search
	IBOutlet NSView *sideSearchView;
	IBOutlet NSSearchField *sideSearchViewField;
	IBOutlet NSTableView *sideSearchViewResults;
	IBOutlet NSArrayController *sideSearchArrayController;
	// Additional stuff
	NSMutableArray *sideSearchResults;
	NSPredicate *sideFilterPredicate;
	NSSortDescriptor *sideSortDescriptor;
	NSString *sideSearchQuery;
	
	//Contents
	IBOutlet NSView *tableOfContentsView;
	IBOutlet NSTableView *tableOfContentsTableView;
	
	//Search view
	IBOutlet NSView *searchView;
	IBOutlet NSSearchField *searchViewField;
	IBOutlet NSPredicateEditor *searchViewPredicateEditor;
	IBOutlet NSTableView *searchViewTable;
	
	NSPredicate *advancedSearchPredicate;
	
	// Other
	IBOutlet IGKArrayController *objectsController;
	IGKSourceListWallpaperView *wallpaperView;
	
	// Temp
	IBOutlet NSTableView *temporaryTable;
	
	
	CHDocsetFilterMode docsetFilterMode;
	
	
	BOOL awaken;
	
	int currentModeIndex;
	
	BOOL shouldIndex;
	
	NSManagedObjectID *objectID;
	
	IBOutlet NSView *noselectionView;
	IBOutlet NSPopUpButton *noselectionPopupButton;
	IBOutlet NSTextField *noselectionSearchField;
	
	IBOutlet NSTextField *urlField;
	IBOutlet NSView *browserTopbar;
	IBOutlet NSView *browserToolbar;
	
	NSArray *tableOfContentsItems;
	BOOL isIndexing;
}

@property (assign) IGKApplicationDelegate *appDelegate;
@property (assign) NSPredicate *sideFilterPredicate;
@property (assign) NSPredicate *advancedFilterPredicate;

@property (assign) NSNumber *ui_currentModeIndex;

@property (assign) BOOL shouldIndex;

@property (assign) CHDocsetFilterMode docsetFilterMode;
@property (assign) NSNumber *ui_docsetFilterMode;

- (IBAction)noselectionSearchField:(id)sender;

- (IBAction)executeSearch:(id)sender;
- (IBAction)executeAdvancedSearch:(id)sender;
- (IBAction)changeViewModeTagged:(id)sender;
- (IBAction)backForward:(id)sender;
- (IBAction)changeViewMode:(id)sender;

- (IBAction)openInSafari:(id)sender;

- (void)setBrowserActive:(BOOL)active;

@end
