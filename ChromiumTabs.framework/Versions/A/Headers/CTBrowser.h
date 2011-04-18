#pragma once
#import <Cocoa/Cocoa.h>
#import "CTTabStripModel.h"
#import "CTTabStripModelDelegate.h"
#import "CTBrowserCommand.h"

enum CTWindowOpenDisposition {
  CTWindowOpenDispositionCurrentTab,
  CTWindowOpenDispositionNewForegroundTab,
  CTWindowOpenDispositionNewBackgroundTab,
};

class CTTabStripModel;
@class CTBrowserWindowController;
@class CTTabContentsController;
@class CTToolbarController;

// There is one CTBrowser instance per percieved window.
// A CTBrowser instance has one TabStripModel.

@interface CTBrowser : NSObject <CTTabStripModelDelegate, NSFastEnumeration> {
  CTTabStripModel *tabStripModel_;
@public
  // Important: Don't ever change this value from user code. It's public just
  // so that the internal machinery can set it at the appropriate time.
  /* bug! __weak */ CTBrowserWindowController *windowController_;
}

// The tab strip model
@property(readonly, nonatomic) CTTabStripModel* tabStripModel;

// The window controller
@property(readonly, nonatomic) /* bug! __weak */ CTBrowserWindowController* windowController;

// The window. Convenience for [windowController window]
@property(readonly, nonatomic) NSWindow* window;

// Create a new browser with a window.
// @autoreleased
+(CTBrowser*)browser;

// Initialize a new browser as the child of windowController
-(id)initWithWindowController:(CTBrowserWindowController*)windowController;

// init
-(id)init;

// Create a new toolbar controller. The default implementation will create a
// controller loaded with a nib called "Toolbar". If the nib can't be found in
// the main bundle, a fallback nib will be loaded from the framework.
// Returning nil means there is no toolbar.
// @autoreleased
-(CTToolbarController *)createToolbarController;

// Create a new tab contents controller. Override this to provide a custom
// CTTabContentsController subclass.
// @autoreleased
-(CTTabContentsController*)createTabContentsControllerWithContents:
    (CTTabContents*)contents;

// Create a new default/blank CTTabContents.
// |baseContents| represents the CTTabContents which is currently in the
// foreground. It might be nil.
// Subclasses could override this to provide a custom CTTabContents type.
// @autoreleased
-(CTTabContents*)createBlankTabBasedOn:(CTTabContents*)baseContents;

// Add blank tab
-(CTTabContents*)addBlankTabAtIndex:(int)index inForeground:(BOOL)foreground;
-(CTTabContents*)addBlankTabInForeground:(BOOL)foreground;
-(CTTabContents*)addBlankTab; // inForeground:YES

// Add tab with contents
-(CTTabContents*)addTabContents:(CTTabContents*)contents
                        atIndex:(int)index
                   inForeground:(BOOL)foreground;
-(CTTabContents*)addTabContents:(CTTabContents*)contents
                   inForeground:(BOOL)foreground;
-(CTTabContents*)addTabContents:(CTTabContents*)contents; // inForeground:YES

// Commands -- TODO: move to CTBrowserWindowController
-(void)newWindow;
-(void)closeWindow;
-(void)closeTab;
-(void)selectNextTab;
-(void)selectPreviousTab;
-(void)moveTabNext;
-(void)moveTabPrevious;
-(void)selectTabAtIndex:(int)index;
-(void)selectLastTab;
-(void)duplicateTab;

-(void)executeCommand:(int)cmd
      withDisposition:(CTWindowOpenDisposition)disposition;
-(void)executeCommand:(int)cmd;

// Execute a command which does not need to have a valid browser. This can be
// used in application delegates or other non-chromium-tabs windows which are
// first responders. Like this:
//
// - (void)commandDispatch:(id)sender {
//   [MyBrowser executeCommand:[sender tag]];
// }
//
+(void)executeCommand:(int)cmd;

// callbacks
-(void)loadingStateDidChange:(CTTabContents*)contents;
-(void)windowDidBeginToClose;

// Convenience helpers (proxy for TabStripModel)
-(int)tabCount;
-(int)selectedTabIndex;
-(CTTabContents*)selectedTabContents;
-(CTTabContents*)tabContentsAtIndex:(int)index;
-(NSArray*)allTabContents;
-(int)indexOfTabContents:(CTTabContents*)contents; // -1 if not found
-(void)selectTabContentsAtIndex:(int)index userGesture:(BOOL)userGesture;
-(void)updateTabStateAtIndex:(int)index;
-(void)updateTabStateForContent:(CTTabContents*)contents;
-(void)replaceTabContentsAtIndex:(int)index
                 withTabContents:(CTTabContents*)contents;
-(void)closeTabAtIndex:(int)index makeHistory:(BOOL)makeHistory;
-(void)closeAllTabs;

@end
