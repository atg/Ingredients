#import <Cocoa/Cocoa.h>
#import "scoped_ptr.h"
#import "scoped_nsobject.h"
#import "url_drop_target.h"

@class CTBrowser;
@class CTTabContents;

// A controller for the toolbar in the browser window.
//
// This class is meant to be subclassed -- the default implementation will load
// a placeholder/dummy nib. You need to do two things:
//
// 1. Create a new subclass of CTToolbarController.
//
// 2. Copy the Toolbar.xib into your project (or create a new) and modify it as
//    needed (add buttons etc). Make sure the "files owner" type matches your
//    CTToolbarController subclass.
//
// 3. Implement createToolbarController in your CTBrowser subclass to initialize
//    and return a CTToolbarController based on your nib.
//
@interface CTToolbarController : NSViewController<URLDropTargetController> {
  /* bug! __weak */ CTBrowser* browser_;  // weak, one per window
 @private
  // Tracking area for mouse enter/exit/moved in the toolbar.
  scoped_nsobject<NSTrackingArea> trackingArea_;
}

- (id)initWithNibName:(NSString*)nibName
               bundle:(NSBundle*)bundle
              browser:(CTBrowser*)browser;

// Set the opacity of the divider (the line at the bottom) *if* we have a
// |ToolbarView| (0 means don't show it); no-op otherwise.
- (void)setDividerOpacity:(CGFloat)opacity;

// Called when the current tab is changing. Subclasses should implement this to
// update the toolbar's state.
- (void)updateToolbarWithContents:(CTTabContents*)contents
               shouldRestoreState:(BOOL)shouldRestore;

// Called by the Window delegate so we can provide a custom field editor if
// needed.
// Note that this may be called for objects unrelated to the toolbar.
// returns nil if we don't want to override the custom field editor for |obj|.
// The default implementation returns nil
- (id)customFieldEditorForObject:(id)obj;

@end
