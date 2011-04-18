// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE-chromium file.

#ifndef CHROME_BROWSER_COCOA_FAST_RESIZE_VIEW_H_
#define CHROME_BROWSER_COCOA_FAST_RESIZE_VIEW_H_
#pragma once

#import <Cocoa/Cocoa.h>

// A Cocoa view that supports an alternate resizing mode, normally used when
// animations are in progress.  In normal resizing mode, subviews are sized to
// completely fill this view's bounds.  In fast resizing mode, the subviews'
// size is not changed and the subview is clipped to fit, if necessary.  Fast
// resize mode is useful when animating a view that normally takes a significant
// amount of time to relayout and redraw when its size is changed.
@interface FastResizeView : NSView {
 @private
  BOOL fastResizeMode_;
}

// Turns fast resizing mode on or off, which determines how this view resizes
// its subviews.  Turning fast resizing mode off has the effect of immediately
// resizing subviews to fit; callers do not need to explictly call |setFrame:|
// to trigger a resize.
- (void)setFastResizeMode:(BOOL)fastResizeMode;
@end

#endif  // CHROME_BROWSER_COCOA_FAST_RESIZE_VIEW_H_
