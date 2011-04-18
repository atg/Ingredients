// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE-chromium file.

#ifndef CHROME_BROWSER_COCOA_TAB_CONTROLLER_TARGET_H_
#define CHROME_BROWSER_COCOA_TAB_CONTROLLER_TARGET_H_
#pragma once

@class CTTabController;

// A protocol to be implemented by a CTTabController's target.
@protocol CTTabControllerTarget
- (void)selectTab:(id)sender;
- (void)closeTab:(id)sender;

// Dispatch context menu commands for the given tab controller.
//- (void)commandDispatch:(TabStripModel::ContextMenuCommand)command
//          forController:(CTTabController*)controller;
// Returns YES if the specificed command should be enabled for the given
// controller.
//- (BOOL)isCommandEnabled:(TabStripModel::ContextMenuCommand)command
//           forController:(CTTabController*)controller;
@end

#endif  // CHROME_BROWSER_COCOA_TAB_CONTROLLER_TARGET_H_
