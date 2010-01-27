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

typedef enum {
	
	CHDocumentationBrowserUIMode_BrowserOnly=0,
	CHDocumentationBrowserUIMode_TwoUp=1,
	CHDocumentationBrowserUIMode_AdvancedSearch=2,
	
	CHDocumentationBrowserUIMode_NeedsSetup=20
	
} CHDocumentationBrowserUIMode;

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
	IBOutlet WebView *browserWebView;
	
	//Side Search
	IBOutlet NSView *sideSearchView;
	IBOutlet NSSearchField *sideSearchViewField;
	IBOutlet NSTableView *sideSearchViewResults;
	IBOutlet NSArrayController *sideSearchArrayController;
	// // Additional stuff
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
	
	IBOutlet NSArrayController *objectsController;
	
	//temp
	IBOutlet NSTableView *temporaryTable;
	
	
	BOOL awaken;
	
	int currentModeIndex;
}

@property (assign) IGKApplicationDelegate *appDelegate;
@property (assign) NSPredicate *sideFilterPredicate;
@property (assign) NSPredicate *advancedFilterPredicate;

@property (assign) NSNumber *ui_currentModeIndex;

- (IBAction)executeSearch:(id)sender;
- (IBAction)changeViewModeTagged:(id)sender;
- (IBAction)backForward:(id)sender;
- (IBAction)changeViewMode:(id)sender;

@end
