// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once
#import <Cocoa/Cocoa.h>
#import "scoped_nsobject.h"

// Offset from the top of the window frame to the top of the window controls
// (zoom, close, miniaturize) for a window with a tabstrip.
const NSInteger CTWindowButtonsWithTabStripOffsetFromTop = 6;

// Offset from the top of the window frame to the top of the window controls
// (zoom, close, miniaturize) for a window without a tabstrip.
const NSInteger CTWindowButtonsWithoutTabStripOffsetFromTop = 4;

// Offset from the left of the window frame to the top of the window controls
// (zoom, close, miniaturize).
const NSInteger CTWindowButtonsOffsetFromLeft = 8;

// Offset between the window controls (zoom, close, miniaturize).
const NSInteger CTWindowButtonsInterButtonSpacing = 7;

// Cocoa class representing a Chrome browser window.
// We need to override NSWindow with our own class since we need access to all
// unhandled keyboard events and subclassing NSWindow is the only method to do
// this. We also handle our own window controls and custom window frame drawing.
@interface CTBrowserWindow : NSWindow {
 @private
  BOOL shouldHideTitle_;
  NSButton* closeButton_;
  NSButton* miniaturizeButton_;
  NSButton* zoomButton_;
  BOOL entered_;
  scoped_nsobject<NSTrackingArea> widgetTrackingArea_;
}

// Tells the window to suppress title drawing.
- (void)setShouldHideTitle:(BOOL)flag;

// Return true if the mouse is currently in our tracking area for our window
// widgets.
- (BOOL)mouseInGroup:(NSButton*)widget;

// Update the tracking areas for our window widgets as appropriate.
- (void)updateTrackingAreas;

@end

@interface NSWindow (UndocumentedAPI)

// Undocumented Cocoa API to suppress drawing of the window's title.
// -setTitle: still works, but the title set only applies to the
// miniwindow and menus (and, importantly, Expose).  Overridden to
// return |shouldHideTitle_|.
-(BOOL)_isTitleHidden;

@end
