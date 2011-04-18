#pragma once

@class CTBrowser;
#import "CTTabContents.h"

//
// CTTabStripModelDelegate
//
// A delegate interface that the CTTabStripModel uses to perform work that it
// can't do itself, such as obtain a container for creating new CTTabContents,
// creating new TabStripModels for detached tabs, etc.
//
// This interface is typically implemented by the controller that instantiates
// the CTTabStripModel (the CTBrowser object).
//
@protocol CTTabStripModelDelegate
// Adds what the delegate considers to be a blank tab to the model.
-(CTTabContents*)addBlankTabInForeground:(BOOL)foreground;
-(CTTabContents*)addBlankTabAtIndex:(int)index inForeground:(BOOL)foreground;

// Asks for a new TabStripModel to be created and the given tab contents to
// be added to it. Its size and position are reflected in |window_bounds|.
// If |dock_info|'s type is other than NONE, the newly created window should
// be docked as identified by |dock_info|. Returns the CTBrowser object
// representing the newly created window and tab strip. This does not
// show the window, it's up to the caller to do so.
-(CTBrowser*)createNewStripWithContents:(CTTabContents*)contents;

// Creates a new CTBrowser object and window containing the specified
// |contents|, and continues a drag operation that began within the source
// window's tab strip. |window_bounds| are the bounds of the source window in
// screen coordinates, used to place the new window, and |tab_bounds| are the
// bounds of the dragged Tab view in the source window, in screen coordinates,
// used to place the new Tab in the new window.
-(void)continueDraggingDetachedTab:(CTTabContents*)contents
                      windowBounds:(const NSRect)windowBounds
                         tabBounds:(const NSRect)tabBounds;

// Returns whether some contents can be duplicated.
-(BOOL)canDuplicateContentsAt:(int)index;

// Duplicates the contents at the provided index and places it into its own
// window.
-(void)duplicateContentsAt:(int)index;

// Called when a drag session has completed and the frame that initiated the
// the session should be closed.
-(void)closeFrameAfterDragSession;

// Creates an entry in the historical tab database for the specified
// CTTabContents.
-(void)createHistoricalTab:(CTTabContents*)contents;

// Runs any unload listeners associated with the specified CTTabContents before
// it is closed. If there are unload listeners that need to be run, this
// function returns true and the TabStripModel will wait before closing the
// CTTabContents. If it returns false, there are no unload listeners and the
// TabStripModel can close the CTTabContents immediately.
-(BOOL)runUnloadListenerBeforeClosing:(CTTabContents*)contents;

// Returns true if a tab can be restored.
-(BOOL)canRestoreTab;

// Restores the last closed tab if CanRestoreTab would return true.
-(void)restoreTab;

// Returns whether some contents can be closed.
-(BOOL)canCloseContentsAt:(int)index;

// Returns true if any of the tabs can be closed.
-(BOOL)canCloseTab;

@end  // @protocol CTTabStripModelDelegate
