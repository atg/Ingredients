#import <Cocoa/Cocoa.h>
#import "CTBrowser.h"
#import "CTTabStripModelDelegate.h"
#import "CTTabWindowController.h"
#import "CTTabStripModelObserverBridge.h"

@class CTTabStripController;
@class CTToolbarController;
//class CTTabStripModelObserverBridge;

@interface NSDocumentController (CTBrowserWindowControllerAdditions)
- (id)openUntitledDocumentWithWindowController:(NSWindowController*)windowController
                                       display:(BOOL)display
                                         error:(NSError **)outError;
@end

@interface CTBrowserWindowController : CTTabWindowController {
  CTBrowser* browser_; // we own the browser
  CTTabStripController *tabStripController_;
  CTTabStripModelObserverBridge *tabStripObserver_;
  CTToolbarController *toolbarController_;
 @private
  BOOL initializing_; // true if the instance is initializing
}

@property(readonly, nonatomic) CTTabStripController *tabStripController;
@property(readonly, nonatomic) CTToolbarController *toolbarController;
@property(readonly, nonatomic) CTBrowser *browser;
@property(readonly, nonatomic) BOOL isFullscreen; // fullscreen or not

// Called to check whether or not this window has a toolbar. By default returns
// true if toolbarController_ is not nil.
@property(readonly, nonatomic) BOOL hasToolbar;

// Returns the current "main" CTBrowserWindowController, or nil if none. "main"
// means the window controller's window is the main window. Useful when there's
// a need to e.g. add contents to the "best window from the users perspective".
+ (CTBrowserWindowController*)mainBrowserWindowController;

// Returns the window controller for |window| or nil if none found
+ (CTBrowserWindowController*)browserWindowControllerForWindow:(NSWindow*)window;

// Returns the window controller for |view| or nil if none found
+ (CTBrowserWindowController*)browserWindowControllerForView:(NSView*)view;

// alias for [[[isa alloc] init] autorelease]
+ (CTBrowserWindowController*)browserWindowController;

- (id)initWithWindowNibPath:(NSString *)windowNibPath
                    browser:(CTBrowser*)browser;
- (id)initWithBrowser:(CTBrowser *)browser;
- (id)init;

// Gets the pattern phase for the window.
- (NSPoint)themePatternPhase;

- (IBAction)saveAllDocuments:(id)sender;
- (IBAction)openDocument:(id)sender;
- (IBAction)newDocument:(id)sender;

// Returns the selected (active) tab, or nil if there are no tabs.
- (CTTabContents*)selectedTabContents;

// Returns the index of the selected (active) tab, or -1 if there are no tabs.
- (int)selectedTabIndex;

// Updates the toolbar with the states of the specified |contents|.
// If |shouldRestore| is true, we're switching (back?) to this tab and should
// restore any previous state (such as user editing a text field) as well.
- (void)updateToolbarWithContents:(CTTabContents*)tab
               shouldRestoreState:(BOOL)shouldRestore;

// Brings this controller's window to the front.
- (void)activate;

// Make the (currently-selected) tab contents the first responder, if possible.
- (void)focusTabContents;

// Lays out the tab content area in the given frame. If the height changes,
// sends a message to the renderer to resize.
- (void)layoutTabContentArea:(NSRect)frame;

@end
