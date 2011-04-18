// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE-chromium file.

#ifndef CHROME_BROWSER_COCOA_TAB_STRIP_VIEW_H_
#define CHROME_BROWSER_COCOA_TAB_STRIP_VIEW_H_
#pragma once

#import <Cocoa/Cocoa.h>

#import "scoped_nsobject.h"
#import "url_drop_target.h"

@class NewTabButton;

// A view class that handles rendering the tab strip and drops of URLS with
// a positioning locator for drop feedback.

@interface CTTabStripView : NSView<URLDropTarget> {
 @private
  NSTimeInterval lastMouseUp_;

  // Handles being a drag-and-drop target.
  scoped_nsobject<URLDropTargetHandler> dropHandler_;

  // Weak; the following come from the nib.
  NewTabButton* newTabButton_;

  // Whether the drop-indicator arrow is shown, and if it is, the coordinate of
  // its tip.
  BOOL dropArrowShown_;
  NSPoint dropArrowPosition_;
}

@property(assign, nonatomic) IBOutlet NewTabButton* newTabButton;
@property(assign, nonatomic) BOOL dropArrowShown;
@property(assign, nonatomic) NSPoint dropArrowPosition;

@end

// Protected methods subclasses can override to alter behavior. Clients should
// not call these directly.
@interface CTTabStripView(Protected)
- (void)drawBottomBorder:(NSRect)bounds;
- (BOOL)doubleClickMinimizesWindow;
@end

#endif  // CHROME_BROWSER_COCOA_TAB_STRIP_VIEW_H_
