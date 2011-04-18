/*
 * KVOChangeScope -- Conveniently mark edits for Key-Value Observations in
 * Objective-C++ in custom setters.
 *
 * Example:
 *
 *    - (void)setFoo:(id)value {
 *       kvo_scoped_change(foo);
 *       // your setter code here which might return at any moment
 *    }
 *
 * This works by placing a KVOChangeScope on the stack, which will take care of
 * sending |willChangeValueForKey| when created and automatically send
 * |didChangeValueForKey| as soon as the method return.
 *
 * There are also some convenience macros, like |kvo_scoped_change| used in the
 * example above. The example above, but without using any macros is equivalent
 * to this code:
 *
 *    - (void)setFoo:(id)value {
 *       KVOChangeScope change_scope(self, foo);
 *       // your setter code here which might return at any moment
 *    }
 *
 * Another useful macro is the limited scope |kvo_change| used for a more fine-
 * grained control of the "will"-to-"did" scope. Here's an illustrating example:
 *
 *    - (void)doSomethingComplex {
 *       // modify value of foo
 *       kvo_change(foo) {
 *         foo_ = @"Foo value 1";
 *         if (bar)
 *           foo_ = @"Foo value 2";
 *       } // <-- didChangeValueForKey:@"foo" called here
 *       // maybe perform slow, blocking I/O here
 *       // modify value of interwebs
 *       kvo_change(interwebs) interwebs_ = @"awesome";
 *       // didChangeValueForKey:@"interwebs" called here
 *       // maybe do some more slow stuff, not holding "edit locks" thus
 *       // avoiding other threads to wait on edit completion.
 *    }
 *
 * MIT license:
 *
 * Copyright 2010 Rasmus Andersson. All rights reserved.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */
#ifndef KVO_CHANGE_SCOPE_HH_
#define KVO_CHANGE_SCOPE_HH_

#ifndef __cplusplus
#error File included in non-C++ source
#endif

#import <Cocoa/Cocoa.h>

class KVOChangeScope {
 public:
  // Constructor which calls |begin| if |beginImmediately| is true
  KVOChangeScope(id owner, NSString *key, bool beginImmediately=true)
      : active_(false) {
    owner_ = [owner retain];
    key_ = [key retain];
    if (beginImmediately) begin();
  }
  
  // Destructor which ends the edit if active
  ~KVOChangeScope() {
    end();
    [key_ release];
    [owner_ release];
  }
  
  // Begin an edit. Returns true if the edit was not already started.
  inline bool begin() {
    if (!active_) {
      [owner_ willChangeValueForKey:key_];
      active_ = true;
      return true;
    }
    return false;
  }
  
  // End an edit. Returns true if there was an active edit which ended.
  inline bool end() {
    if (active_) {
      [owner_ didChangeValueForKey:key_];
      active_ = false;
      return true;
    }
    return false;
  }

 protected:
  bool active_;
  id owner_;
  NSString *key_;

 private:
  // disallow copy and assign
  KVOChangeScope(const KVOChangeScope&);
  void operator=(const KVOChangeScope&);
};

// Convenience macros, using keys as stack variable names so to both disallow
// multiple active change transactions for the same key, but at the same time
// allow for multiple active change transactions of _different_ keys.

#define kvo_scoped_change(key) KVOChangeScope _kvocs_##key(self, @#key)

#define kvo_change(key) \
  for (KVOChangeScope _kvocs_##key(self, @#key, false); _kvocs_##key.begin(); )

#define kvo_change2(owner, key) \
  for (KVOChangeScope _kvocs_##key(owner, @#key, false); _kvocs_##key.begin(); )

#endif  // KVO_CHANGE_SCOPE_HH_
