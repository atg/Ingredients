// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE-chromium file.

#ifndef CHROME_BROWSER_TAB_WINDOW_CONTROLLER_H_
#define CHROME_BROWSER_TAB_WINDOW_CONTROLLER_H_
#pragma once

// A class acting as the Objective-C window controller for a window that has
// tabs which can be dragged around. Tabs can be re-arranged within the same
// window or dragged into other CTTabWindowController windows. This class doesn't
// know anything about the actual tab implementation or model, as that is fairly
// application-specific. It only provides an API to be overridden by subclasses
// to fill in the details.
//
// This assumes that there will be a view in the nib, connected to
// |tabContentArea_|, that indicates the content that it switched when switching
// between tabs. It needs to be a regular NSView, not something like an NSBox
// because the CTTabStripController makes certain assumptions about how it can
// swap out subviews.
//
// The tab strip can exist in different orientations and window locations,
// depending on the return value of -usesVerticalTabs. If NO (the default),
// the tab strip is placed outside the window's content area, overlapping the
// title area and window controls and will be stretched to fill the width
// of the window. If YES, the tab strip is vertical and lives within the
// window's content area. It will be stretched to fill the window's height.

#import <Cocoa/Cocoa.h>

#import "cocoa_protocols_mac.h"
#import "scoped_nsobject.h"

@class FastResizeView;
@class CTTabStripView;
@class CTTabView;

@interface CTTabWindowController : NSWindowController<NSWindowDelegate> {
 @private
  IBOutlet FastResizeView* tabContentArea_;
  // TODO(pinkerton): Figure out a better way to initialize one or the other
  // w/out needing both to be in the nib.
  IBOutlet CTTabStripView* topTabStripView_;
  IBOutlet CTTabStripView* sideTabStripView_;
  NSWindow* overlayWindow_;  // Used during dragging for window opacity tricks
  NSView* cachedContentView_;  // Used during dragging for identifying which
                               // view is the proper content area in the overlay
                               // (weak)
  scoped_nsobject<NSMutableSet> lockedTabs_;
  BOOL closeDeferred_;  // If YES, call performClose: in removeOverlay:.
  // Difference between height of window content area and height of the
  // |tabContentArea_|. Calculated when the window is loaded from the nib and
  // cached in order to restore the delta when switching tab modes.
  CGFloat contentAreaHeightDelta_;
  
  BOOL didShowNewTabButtonBeforeTemporalAction_;
}
@property(readonly, nonatomic) CTTabStripView* tabStripView;
@property(readonly, nonatomic) FastResizeView* tabContentArea;
@property(assign, nonatomic) BOOL didShowNewTabButtonBeforeTemporalAction;

// Used during tab dragging to turn on/off the overlay window when a tab
// is torn off. If -deferPerformClose (below) is used, -removeOverlay will
// cause the controller to be autoreleased before returning.
- (void)showOverlay;
- (void)removeOverlay;
- (NSWindow*)overlayWindow;

// Returns YES if it is ok to constrain the window's frame to fit the screen.
- (BOOL)shouldConstrainFrameRect;

// A collection of methods, stubbed out in this base class, that provide
// the implementation of tab dragging based on whatever model is most
// appropriate.

// Layout the tabs based on the current ordering of the model.
- (void)layoutTabs;

// Creates a new window by pulling the given tab out and placing it in
// the new window. Returns the controller for the new window. The size of the
// new window will be the same size as this window.
- (CTTabWindowController*)detachTabToNewWindow:(CTTabView*)tabView;

// Make room in the tab strip for |tab| at the given x coordinate. Will hide the
// new tab button while there's a placeholder. Subclasses need to call the
// superclass implementation.
- (void)insertPlaceholderForTab:(CTTabView*)tab
                          frame:(NSRect)frame
                  yStretchiness:(CGFloat)yStretchiness;

// Removes the placeholder installed by |-insertPlaceholderForTab:atLocation:|
// and restores the new tab button. Subclasses need to call the superclass
// implementation.
- (void)removePlaceholder;

// The follow return YES if tab dragging/tab tearing (off the tab strip)/window
// movement is currently allowed. Any number of things can choose to disable it,
// such as pending animations. The default implementations always return YES.
// Subclasses should override as appropriate.
- (BOOL)tabDraggingAllowed;
- (BOOL)tabTearingAllowed;
- (BOOL)windowMovementAllowed;

// Called when dragging of teared tab in an overlay window occurs
-(void)willStartTearingTab;
-(void)willEndTearingTab;
-(void)didEndTearingTab;

// Show or hide the new tab button. The button is hidden immediately, but
// waits until the next call to |-layoutTabs| to show it again.
@property(nonatomic, assign) BOOL showsNewTabButton;

// Returns whether or not |tab| can still be fully seen in the tab strip or if
// its current position would cause it be obscured by things such as the edge
// of the window or the window decorations. Returns YES only if the entire tab
// is visible. The default implementation always returns YES.
- (BOOL)isTabFullyVisible:(CTTabView*)tab;

// Called to check if the receiver can receive dragged tabs from
// source.  Return YES if so.  The default implementation returns NO.
- (BOOL)canReceiveFrom:(CTTabWindowController*)source;

// Move a given tab view to the location of the current placeholder. If there is
// no placeholder, it will go at the end. |controller| is the window controller
// of a tab being dropped from a different window. It will be nil if the drag is
// within the window, otherwise the tab is removed from that window before being
// placed into this one. The implementation will call |-removePlaceholder| since
// the drag is now complete.  This also calls |-layoutTabs| internally so
// clients do not need to call it again.
- (void)moveTabView:(NSView*)view
     fromController:(CTTabWindowController*)controller;

// Number of tabs in the tab strip. Useful, for example, to know if we're
// dragging the only tab in the window. This includes pinned tabs (both live
// and not).
- (NSInteger)numberOfTabs;

// YES if there are tabs in the tab strip which have content, allowing for
// the notion of tabs in the tab strip that are placeholders, or phantoms, but
// currently have no content.
- (BOOL)hasLiveTabs;

// Return the view of the selected tab.
- (NSView *)selectedTabView;

// The title of the selected tab.
- (NSString*)selectedTabTitle;

// Called to check whether or not this controller's window has a tab strip (YES
// if it does, NO otherwise). The default implementation returns YES.
- (BOOL)hasTabStrip;

// Returns YES if the tab strip lives in the window content area alongside the
// tab contents. Returns NO if the tab strip is outside the window content
// area, along the top of the window.
- (BOOL)useVerticalTabs;

// Get/set whether a particular tab is draggable between windows.
- (BOOL)isTabDraggable:(NSView*)tabView;
- (void)setTab:(NSView*)tabView isDraggable:(BOOL)draggable;

// Tell the window that it needs to call performClose: as soon as the current
// drag is complete. This prevents a window (and its overlay) from going away
// during a drag.
- (void)deferPerformClose;

@end

@interface CTTabWindowController(ProtectedMethods)
// Tells the tab strip to forget about this tab in preparation for it being
// put into a different tab strip, such as during a drop on another window.
- (void)detachTabView:(NSView*)view;

// Toggles from one display mode of the tab strip to another. Will automatically
// call -layoutSubviews to reposition other content.
- (void)toggleTabStripDisplayMode;

// Called when the size of the window content area has changed. Override to
// position specific views. Base class implementation does nothing.
- (void)layoutSubviews;
@end

#endif  // CHROME_BROWSER_TAB_WINDOW_CONTROLLER_H_
