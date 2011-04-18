// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE-chromium file.

#ifndef CHROME_COMMON_PAGE_TRANSITION_TYPES_H__
#define CHROME_COMMON_PAGE_TRANSITION_TYPES_H__
#pragma once

#import <stdint.h>

// Types of transitions between pages. These are stored in the history
// database to separate visits, and are reported by the renderer for page
// navigations.
//
// WARNING: don't change these numbers. They are written directly into the
// history database, so future versions will need the same values to match
// the enums.
//
// A type is made of a core value and a set of qualifiers. A type has one
// core value and 0 or or more qualifiers.
typedef enum {
  // User got to this page by clicking a link on another page.
  CTPageTransitionLink = 0,

  // User got this page by typing the URL in the URL bar.  This should not be
  // used for cases where the user selected a choice that didn't look at all
  // like a URL; see Generated below.
  //
  // We also use this for other "explicit" navigation actions.
  CTPageTransitionTyped = 1,

  // User got to this page through a suggestion in the UI, for example,
  // through the destinations page.
  CTPageTransitionAutoBookmark = 2,

  // This is a subframe navigation. This is any content that is automatically
  // loaded in a non-toplevel frame. For example, if a page consists of
  // several frames containing ads, those ad URLs will have this transition
  // type. The user may not even realize the content in these pages is a
  // separate frame, so may not care about the URL (see Manual below).
  CTPageTransitionAutoSubframe = 3,

  // For subframe navigations that are explicitly requested by the user and
  // generate new navigation entries in the back/forward list. These are
  // probably more important than frames that were automatically loaded in
  // the background because the user probably cares about the fact that this
  // link was loaded.
  CTPageTransitionManualSubframe = 4,

  // User got to this page by typing in the URL bar and selecting an entry
  // that did not look like a URL.  For example, a match might have the URL
  // of a Google search result page, but appear like "Search Google for ...".
  // These are not quite the same as Typed navigations because the user
  // didn't type or see the destination URL.
  // See also Keyword.
  CTPageTransitionGenerated = 5,

  // The page was specified in the command line or is the start page.
  CTPageTransitionStartPage = 6,

  // The user filled out values in a form and submitted it. NOTE that in
  // some situations submitting a form does not result in this transition
  // type. This can happen if the form uses script to submit the contents.
  CTPageTransitionFormSubmit = 7,

  // The user "reloaded" the page, either by hitting the reload button or by
  // hitting enter in the address bar.  NOTE: This is distinct from the
  // concept of whether a particular load uses "reload semantics" (i.e.
  // bypasses cached data).  For this reason, lots of code needs to pass
  // around the concept of whether a load should be treated as a "reload"
  // separately from their tracking of this transition type, which is mainly
  // used for proper scoring for consumers who care about how frequently a
  // user typed/visited a particular URL.
  //
  // SessionRestore and undo tab close use this transition type too.
  CTPageTransitionReload = 8,

  // The url was generated from a replaceable keyword other than the default
  // search provider. If the user types a keyword (which also applies to
  // tab-to-search) in the omnibox this qualifier is applied to the transition
  // type of the generated url. TemplateURLModel then may generate an
  // additional visit with a transition type of KeywordGenerated against the
  // url 'http://' + keyword. For example, if you do a tab-to-search against
  // wikipedia the generated url has a transition qualifer of Keyword, and
  // TemplateURLModel generates a visit for 'wikipedia.org' with a transition
  // type of KeywordGenerated.
  CTPageTransitionKeyword = 9,

  // Corresponds to a visit generated for a keyword. See description of
  // KEYWORD for more details.
  CTPageTransitionKeywordGenerated = 10,

  // ADDING NEW CORE VALUE? Be sure to update the LastCore and CoreMask
  // values below.  Also update CoreTransitionString().
  CTPageTransitionLastCore = CTPageTransitionKeywordGenerated,
  CTPageTransitionCoreMask = 0xFF,

  // Qualifiers
  // Any of the core values above can be augmented by one or more qualifiers.
  // These qualifiers further define the transition.

  // The beginning of a navigation chain.
  CTPageTransitionChainStart = 0x10000000,

  // The last transition in a redirect chain.
  CTPageTransitionChainEnd = 0x20000000,

  // Redirects caused by JavaScript or a meta refresh tag on the page.
  CTPageTransitionClientRedirect = 0x40000000,

  // Redirects sent from the server by HTTP headers. It might be nice to
  // break this out into 2 types in the future, permanent or temporary, if we
  // can get that information from WebKit.
  CTPageTransitionServerRedirect = 0x80000000,

  // Used to test whether a transition involves a redirect.
  CTPageTransitionIsRedirectMask = 0xC0000000,

  // General mask defining the bits used for the qualifiers.
  CTPageTransitionQualifierMask = 0xFFFFFF00

} CTPageTransition;


// Simplifies the provided transition by removing any qualifier
inline CTPageTransition CTPageTransitionStripQualifier(CTPageTransition type) {
  return (CTPageTransition)(type & ~CTPageTransitionQualifierMask);
}

inline int CTPageTransitionValidType(CTPageTransition type) {
  CTPageTransition t = CTPageTransitionStripQualifier(type);
  return !!(t <= CTPageTransitionLastCore); // Boolean
}

// Returns true if the given transition is a top-level frame transition, or
// false if the transition was for a subframe. Boolean.
inline int CTPageTransitionIsMainFrame(CTPageTransition type) {
  CTPageTransition t = CTPageTransitionStripQualifier(type);
  return !!(t != CTPageTransitionAutoSubframe &&
          t != CTPageTransitionManualSubframe);
}

// Returns whether a transition involves a redirection. Boolean.
inline int CTPageTransitionIsRedirect(CTPageTransition type) {
  return (type & CTPageTransitionIsRedirectMask) != 0;
}

// Return the qualifier
inline int CTPageTransitionGetQualifier(CTPageTransition type) {
  return type & CTPageTransitionQualifierMask;
}

inline CTPageTransition CTPageTransitionFromInt(CTPageTransition type) {
  if (!CTPageTransitionValidType(type)) {
    // Return a safe default so we don't have corrupt data
    return CTPageTransitionLink;
  }
  return (CTPageTransition)(type);
}

// Return a string version of the core type values.
const char* CTPageTransitionCoreString(CTPageTransition type);


#endif  // CHROME_COMMON_PAGE_TRANSITION_TYPES_H__
