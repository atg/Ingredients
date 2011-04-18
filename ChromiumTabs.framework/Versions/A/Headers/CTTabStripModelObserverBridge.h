// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE-chromium file.

#ifndef CHROME_BROWSER_COCOA_TAB_STRIP_MODEL_OBSERVER_BRIDGE_H_
#define CHROME_BROWSER_COCOA_TAB_STRIP_MODEL_OBSERVER_BRIDGE_H_
#pragma once

#import <Foundation/Foundation.h>

#import "CTTabStripModel.h"

@class CTTabContents;

// A C++ bridge class to handle receiving notifications from the C++ tab strip
// model. When the caller allocates a bridge, it automatically registers for
// notifications from |model| and passes messages to |controller| via the
// informal protocol below. The owner of this object is responsible for deleting
// it (and thus unhooking notifications) before |controller| is destroyed.
class CTTabStripModelObserverBridge : public CTTabStripModelObserver {
 public:
  CTTabStripModelObserverBridge(CTTabStripModel* model, id controller);
  virtual ~CTTabStripModelObserverBridge();

  // Overridden from TabStripModelObserver
  bool TabInsertedAtOK_;
  virtual void TabInsertedAt(CTTabContents* contents,
                             int index,
                             bool foreground);
  bool TabClosingAtOK_;
  virtual void TabClosingAt(CTTabContents* contents, int index);
  bool TabDetachedAtOK_;
  virtual void TabDetachedAt(CTTabContents* contents, int index);
  bool TabSelectedAtOK_;
  virtual void TabSelectedAt(CTTabContents* old_contents,
                             CTTabContents* new_contents,
                             int index,
                             bool user_gesture);
  bool TabMovedOK_;
  virtual void TabMoved(CTTabContents* contents,
                        int from_index,
                        int to_index);
  bool TabChangedAtOK_;
  virtual void TabChangedAt(CTTabContents* contents, int index,
                            CTTabChangeType change_type);
  bool TabReplacedAtOK_;
  virtual void TabReplacedAt(CTTabContents* old_contents,
                             CTTabContents* new_contents,
                             int index);
  bool TabMiniStateChangedOK_;
  virtual void TabMiniStateChanged(CTTabContents* contents, int index);
  bool TabStripEmptyOK_;
  virtual void TabStripEmpty();

 private:
  /* bug! __weak */ id controller_;  // owns me
  /* bug! __weak */ CTTabStripModel* model_;  // owned by CTBrowser
};

// A collection of methods which can be selectively implemented by any
// Cocoa object to receive updates about changes to a tab strip model. It is
// ok to not implement them, the calling code checks before calling.
@interface NSObject(TabStripModelBridge)
- (void)tabInsertedWithContents:(CTTabContents*)contents
                      atIndex:(NSInteger)index
                 inForeground:(bool)inForeground;
- (void)tabReplacedWithContents:(CTTabContents*)contents
                    oldContents:(CTTabContents*)oldContents
                        atIndex:(NSInteger)index;
- (void)tabClosingWithContents:(CTTabContents*)contents
                       atIndex:(NSInteger)index;
- (void)tabDetachedWithContents:(CTTabContents*)contents
                        atIndex:(NSInteger)index;
- (void)tabSelectedWithContents:(CTTabContents*)newContents
             previousContents:(CTTabContents*)oldContents
                      atIndex:(NSInteger)index
                  userGesture:(bool)wasUserGesture;
- (void)tabMovedWithContents:(CTTabContents*)contents
                    fromIndex:(NSInteger)from
                      toIndex:(NSInteger)to;
- (void)tabChangedWithContents:(CTTabContents*)contents
                       atIndex:(NSInteger)index
                    changeType:(CTTabChangeType)change;
- (void)tabMiniStateChangedWithContents:(CTTabContents*)contents
                                atIndex:(NSInteger)index;
- (void)tabStripEmpty;
@end

#endif  // CHROME_BROWSER_COCOA_TAB_STRIP_MODEL_OBSERVER_BRIDGE_H_
