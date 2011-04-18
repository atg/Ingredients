// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CHROME_BROWSER_COCOA_THEMED_WINDOW_H_
#define CHROME_BROWSER_COCOA_THEMED_WINDOW_H_
#pragma once

#import <Cocoa/Cocoa.h>

@interface NSWindow (CTThemed)
- (NSPoint)themePatternPhase;
@end

#endif  // CHROME_BROWSER_COCOA_THEMED_WINDOW_H_
