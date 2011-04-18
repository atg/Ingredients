// Copyright (c) 2008 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_SCOPED_NSAUTORELEASE_POOL_H_
#define BASE_SCOPED_NSAUTORELEASE_POOL_H_
#pragma once

#include "basictypes.h"

#if defined(__OBJC__)
@class NSAutoreleasePool;
#else  // __OBJC__
class NSAutoreleasePool;
#endif  // __OBJC__

// On the Mac, ScopedNSAutoreleasePool allocates an NSAutoreleasePool when
// instantiated and sends it a -drain message when destroyed.  This allows an
// autorelease pool to be maintained in ordinary C++ code without bringing in
// any direct Objective-C dependency.
//
// On other platforms, ScopedNSAutoreleasePool is an empty object with no
// effects.  This allows it to be used directly in cross-platform code without
// ugly #ifdefs.
class ScopedNSAutoreleasePool {
 public:
  ScopedNSAutoreleasePool();
  ~ScopedNSAutoreleasePool();

  // Clear out the pool in case its position on the stack causes it to be
  // alive for long periods of time (such as the entire length of the app).
  // Only use then when you're certain the items currently in the pool are
  // no longer needed.
  void Recycle();
 private:
  NSAutoreleasePool* autorelease_pool_;

 private:
  DISALLOW_COPY_AND_ASSIGN(ScopedNSAutoreleasePool);
};

#endif  // BASE_SCOPED_NSAUTORELEASE_POOL_H_
