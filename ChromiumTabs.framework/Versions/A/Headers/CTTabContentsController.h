// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE-chromium file.

#ifndef CHROME_BROWSER_COCOA_TAB_CONTENTS_CONTROLLER_H_
#define CHROME_BROWSER_COCOA_TAB_CONTENTS_CONTROLLER_H_
#pragma once

#import <Cocoa/Cocoa.h>

@class CTTabContents;
class CTTabStripModel;

// A class that controls the contents of a tab. It manages displaying the native
// view for a given CTTabContents in |contentsContainer_|.
// Note that just creating the class does not display the view in
// |contentsContainer_|. We defer inserting it until the box is the correct size
// to avoid multiple resize messages to the renderer. You must call
// |-ensureContentsVisible| to display the render widget host view.

@interface CTTabContentsController : NSViewController {
 @private
  /* bug! __weak */ CTTabContents* contents_;  // weak

  IBOutlet NSSplitView* contentsContainer_;
}

// Create the contents of a tab represented by |contents| and loaded from the
// nib given by |name|.
- (id)initWithNibName:(NSString*)name
               bundle:(NSBundle*)bundle
             contents:(CTTabContents*)contents;

// Create the contents of a tab represented by |contents| and loaded from a nib
// called "TabContents".
//
// Will first try to find a nib named "TabContents" in the main bundle. If the
// "TabContents" nib could not be found in the main bulde it is loaded from the
// framework bundle.
//
// If you use a nib with another name you should override the implementation in
// your subclass and delegate the internal initialization to
// initWithNibName:bundle:contents
- (id)initWithContents:(CTTabContents*)contents;

// Returns YES if the tab represented by this controller is the front-most.
- (BOOL)isCurrentTab;

// Called when the tab contents is the currently selected tab and is about to be
// removed from the view hierarchy.
- (void)willResignSelectedTab;

// Called when the tab contents is about to be put into the view hierarchy as
// the selected tab. Handles things such as ensuring the toolbar is correctly
// enabled.
- (void)willBecomeSelectedTab;

// Call when the tab view is properly sized and the render widget host view
// should be put into the view hierarchy.
- (void)ensureContentsVisible;

// Called when the tab contents is updated in some non-descript way (the
// notification from the model isn't specific). |updatedContents| could reflect
// an entirely new tab contents object.
- (void)tabDidChange:(CTTabContents*)updatedContents;

// Shows |devToolsContents| in a split view, or removes the bottom view in the
// split viewif |devToolsContents| is NULL.
// TODO(thakis): Either move this to tab_window or move infobar handling to here
// too -- http://crbug.com/31633 .
//- (void)showDevToolsContents:(CTTabContents*)devToolsContents;

// Returns the height required by devtools and divider, or 0 if no devtools are
// docked to the tab.
//- (CGFloat)devToolsHeight;
@end

#endif  // CHROME_BROWSER_COCOA_TAB_CONTENTS_CONTROLLER_H_
