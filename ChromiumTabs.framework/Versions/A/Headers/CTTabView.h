// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE-chromium file.

#ifndef CHROME_BROWSER_COCOA_TAB_VIEW_H_
#define CHROME_BROWSER_COCOA_TAB_VIEW_H_
#pragma once

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

#import <map>

#import "scoped_nsobject.h"
#import "background_gradient_view.h"
#import "hover_close_button.h"

namespace tabs {

// Nomenclature:
// Tabs _glow_ under two different circumstances, when they are _hovered_ (by
// the mouse) and when they are _alerted_ (to show that the tab's title has
// changed).

// The state of alerting (to show a title change on an unselected, pinned tab).
// This is more complicated than a simple on/off since we want to allow the
// alert glow to go through a full rise-hold-fall cycle to avoid flickering (or
// always holding).
enum AlertState {
  kAlertNone = 0,  // Obj-C initializes to this.
  kAlertRising,
  kAlertHolding,
  kAlertFalling
};

}  // namespace tabs

@class CTTabController, CTTabWindowController;

// A view that handles the event tracking (clicking and dragging) for a tab
// on the tab strip. Relies on an associated CTTabController to provide a
// target/action for selecting the tab.

@interface CTTabView : BackgroundGradientView {
 @private
  IBOutlet CTTabController* tabController_;
  // TODO(rohitrao): Add this button to a CoreAnimation layer so we can fade it
  // in and out on mouseovers.
  IBOutlet HoverCloseButton* closeButton_;
  BOOL closing_;

  // Tracking area for close button mouseover images.
  scoped_nsobject<NSTrackingArea> closeTrackingArea_;

  BOOL isMouseInside_;  // Is the mouse hovering over?
  tabs::AlertState alertState_;

  CGFloat hoverAlpha_;  // How strong the hover glow is.
  NSTimeInterval hoverHoldEndTime_;  // When the hover glow will begin dimming.

  CGFloat alertAlpha_;  // How strong the alert glow is.
  NSTimeInterval alertHoldEndTime_;  // When the hover glow will begin dimming.

  NSTimeInterval lastGlowUpdate_;  // Time either glow was last updated.

  NSPoint hoverPoint_;  // Current location of hover in view coords.

  // All following variables are valid for the duration of a drag.
  // These are released on mouseUp:
  BOOL moveWindowOnDrag_;  // Set if the only tab of a window is dragged.
  BOOL tabWasDragged_;  // Has the tab been dragged?
  BOOL draggingWithinTabStrip_;  // Did drag stay in the current tab strip?
  BOOL chromeIsVisible_;

  NSTimeInterval tearTime_;  // Time since tear happened
  NSPoint tearOrigin_;  // Origin of the tear rect
  NSPoint dragOrigin_;  // Origin point of the drag
  // TODO(alcor): these references may need to be strong to avoid crashes
  // due to JS closing windows
  CTTabWindowController* sourceController_;  // weak. controller starting the drag
  NSWindow* sourceWindow_;  // weak. The window starting the drag
  NSRect sourceWindowFrame_;
  NSRect sourceTabFrame_;

  CTTabWindowController* draggedController_;  // weak. Controller being dragged.
  NSWindow* dragWindow_;  // weak. The window being dragged
  NSWindow* dragOverlay_;  // weak. The overlay being dragged
  // Cache workspace IDs per-drag because computing them on 10.5 with
  // CGWindowListCreateDescriptionFromArray is expensive.
  // resetDragControllers clears this cache.
  //
  // TODO(davidben): When 10.5 becomes unsupported, remove this.
  std::map<CGWindowID, int> workspaceIDCache_;

  CTTabWindowController* targetController_;  // weak. Controller being targeted
  NSCellStateValue state_;
}

@property(assign, nonatomic) NSCellStateValue state;
@property(assign, nonatomic) CGFloat hoverAlpha;
@property(assign, nonatomic) CGFloat alertAlpha;

// Determines if the tab is in the process of animating closed. It may still
// be visible on-screen, but should not respond to/initiate any events. Upon
// setting to NO, clears the target/action of the close button to prevent
// clicks inside it from sending messages.
@property(assign, nonatomic, getter=isClosing) BOOL closing;

// Enables/Disables tracking regions for the tab.
- (void)setTrackingEnabled:(BOOL)enabled;

// Begin showing an "alert" glow (shown to call attention to an unselected
// pinned tab whose title changed).
- (void)startAlert;

// Stop showing the "alert" glow; this won't immediately wipe out any glow, but
// will make it fade away.
- (void)cancelAlert;

@end

// The CTTabController |tabController_| is not the only owner of this view. If the
// controller is released before this view, then we could be hanging onto a
// garbage pointer. To prevent this, the CTTabController uses this interface to
// clear the |tabController_| pointer when it is dying.
@interface CTTabView (TabControllerInterface)
- (void)setController:(CTTabController*)controller;
- (CTTabController*)controller;
@end

#endif  // CHROME_BROWSER_COCOA_TAB_VIEW_H_
