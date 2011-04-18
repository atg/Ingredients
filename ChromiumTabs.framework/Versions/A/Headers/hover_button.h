// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE-chromium file.

#import <Cocoa/Cocoa.h>

#import "scoped_nsobject.h"

// A button that changes when you hover over it and click it.
@interface HoverButton : NSButton {
 @protected
  // Enumeration of the hover states that the close button can be in at any one
  // time. The button cannot be in more than one hover state at a time.
  enum HoverState {
    kHoverStateNone = 0,
    kHoverStateMouseOver = 1,
    kHoverStateMouseDown = 2
  };

  HoverState hoverState_;

 @private
  // Tracking area for button mouseover states.
  scoped_nsobject<NSTrackingArea> trackingArea_;
}

// Enables or disables the |NSTrackingRect|s for the button.
- (void)setTrackingEnabled:(BOOL)enabled;

// Checks to see whether the mouse is in the button's bounds and update
// the image in case it gets out of sync.  This occurs to the close button
// when you close a tab so the tab to the left of it takes its place, and
// drag the button without moving the mouse before you press the button down.
- (void)checkImageState;
@end
