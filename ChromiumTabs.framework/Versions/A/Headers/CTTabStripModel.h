// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE-chromium file.

#ifndef CHROME_BROWSER_TABS_TAB_STRIP_MODEL_H_
#define CHROME_BROWSER_TABS_TAB_STRIP_MODEL_H_
#pragma once

#import <vector>

#import "CTPageTransition.h"
#import "observer_list.h"

#import "CTTabStripModelDelegate.h"

@class CTTabContents;


//namespace gfx { class Rect; }
//class CTBrowser;
//class DockInfo;
//class GURL;
//class NavigationController;
//class Profile;
//class SiteInstance;
class CTTabStripModelOrderController;
class CTTabStripModel;

// Enumeration of the possible values supplied to TabChangedAt.
enum CTTabChangeType {
  // Only the loading state changed.
  CTTabChangeTypeLoadingOnly,

  // Only the title changed and page isn't loading.
  CTTabChangeTypeTitleNotLoading,

  // Change not characterized by CTTabChangeTypeLoadingOnly or CTTabChangeTypeTitleNotLoading.
  CTTabChangeTypeAll
};

// Enum used by ReplaceTabContentsAt.
enum CTTabReplaceType {
  // The replace is the result of the tab being made phantom.
  REPLACE_MADE_PHANTOM,

  // The replace is the result of the match preview being committed.
  REPLACE_MATCH_PREVIEW
};

////////////////////////////////////////////////////////////////////////////////
//
// TabStripModelObserver
//
//  Objects implement this interface when they wish to be notified of changes
//  to the TabStripModel.
//
//  Two major implementers are the TabStrip, which uses notifications sent
//  via this interface to update the presentation of the strip, and the CTBrowser
//  object, which updates bookkeeping and shows/hides individual TabContentses.
//
//  Register your TabStripModelObserver with the TabStripModel using its
//  Add/RemoveObserver methods.
//
////////////////////////////////////////////////////////////////////////////////
class CTTabStripModelObserver {
 public:
  // A new CTTabContents was inserted into the TabStripModel at the specified
  // index. |foreground| is whether or not it was opened in the foreground
  // (selected).
  virtual void TabInsertedAt(CTTabContents* contents,
                             int index,
                             bool foreground);

  // The specified CTTabContents at |index| is being closed (and eventually
  // destroyed).
  virtual void TabClosingAt(CTTabContents* contents, int index);

  // The specified CTTabContents at |index| is being detached, perhaps to be
  // inserted in another TabStripModel. The implementer should take whatever
  // action is necessary to deal with the CTTabContents no longer being present.
  virtual void TabDetachedAt(CTTabContents* contents, int index);

  // The selected CTTabContents is about to change from |old_contents| at |index|.
  // This gives observers a chance to prepare for an impending switch before it
  // happens.
  virtual void TabDeselectedAt(CTTabContents* contents, int index);

  // The selected CTTabContents changed from |old_contents| to |new_contents| at
  // |index|. |user_gesture| specifies whether or not this was done by a user
  // input event (e.g. clicking on a tab, keystroke) or as a side-effect of
  // some other function.
  virtual void TabSelectedAt(CTTabContents* old_contents,
                             CTTabContents* new_contents,
                             int index,
                             bool user_gesture);

  // The specified CTTabContents at |from_index| was moved to |to_index|.
  virtual void TabMoved(CTTabContents* contents,
                        int from_index,
                        int to_index);

  // The specified CTTabContents at |index| changed in some way. |contents| may
  // be an entirely different object and the old value is no longer available
  // by the time this message is delivered.
  //
  // See TabChangeType for a description of |change_type|.
  virtual void TabChangedAt(CTTabContents* contents, int index,
                            CTTabChangeType change_type);

  // The tab contents was replaced at the specified index. This is invoked when
  // a tab becomes phantom. See description of phantom tabs in class description
  // of TabStripModel for details.
  // TODO(sky): nuke this in favor of the 4 arg variant.
  virtual void TabReplacedAt(CTTabContents* old_contents,
                             CTTabContents* new_contents,
                             int index);

  // The tab contents was replaced at the specified index. |type| describes
  // the type of replace.
  // This invokes TabReplacedAt with three args.
  virtual void TabReplacedAt(CTTabContents* old_contents,
                             CTTabContents* new_contents,
                             int index,
                             CTTabReplaceType type);

  // Invoked when the pinned state of a tab changes. This is not invoked if the
  // tab ends up moving as a result of the mini state changing.
  // See note in TabMiniStateChanged as to how this relates to
  // TabMiniStateChanged.
  virtual void TabPinnedStateChanged(CTTabContents* contents, int index);

  // Invoked if the mini state of a tab changes.  This is not invoked if the
  // tab ends up moving as a result of the mini state changing.
  // NOTE: this is sent when the pinned state of a non-app tab changes and is
  // sent in addition to TabPinnedStateChanged. UI code typically need not care
  // about TabPinnedStateChanged, but instead this.
  virtual void TabMiniStateChanged(CTTabContents* contents, int index);

  // Invoked when the blocked state of a tab changes.
  // NOTE: This is invoked when a tab becomes blocked/unblocked by a tab modal
  // window.
  virtual void TabBlockedStateChanged(CTTabContents* contents, int index);

  // The TabStripModel now no longer has any phantom tabs. The implementer may
  // use this as a trigger to try and close the window containing the
  // TabStripModel, for example...
  virtual void TabStripEmpty();

  // Sent when the tabstrip model is about to be deleted and any reference held
  // must be dropped.
  virtual void TabStripModelDeleted();

 protected:
  virtual ~CTTabStripModelObserver() {}
};


////////////////////////////////////////////////////////////////////////////////
//
// TabStripModel
//
//  A model & low level controller of a CTBrowser Window tabstrip. Holds a vector
//  of CTTabContents, and provides an API for adding, removing and shuffling
//  them, as well as a higher level API for doing specific CTBrowser-related
//  tasks like adding new Tabs from just a URL, etc.
//
// Each tab may be any one of the following states:
// . Mini-tab. Mini tabs are locked to the left side of the tab strip and
//   rendered differently (small tabs with only a favicon). The model makes
//   sure all mini-tabs are at the beginning of the tab strip. For example,
//   if a non-mini tab is added it is forced to be with non-mini tabs. Requests
//   to move tabs outside the range of the tab type are ignored. For example,
//   a request to move a mini-tab after non-mini-tabs is ignored.
//   You'll notice there is no explcit api for making a tab a mini-tab, rather
//   there are two tab types that are implicitly mini-tabs:
//   . App. Corresponds to an extension that wants an app tab. App tabs are
//     identified by CTTabContents::is_app(). App tabs are always pinneded (you
//     can't unpin them).
//   . Pinned. Any tab can be pinned. A pinned tab is made phantom when closed.
//     Non-app tabs whose pinned state is changed are moved to be with other
//     mini-tabs or non-mini tabs.
// . Phantom. Only pinned tabs may be made phantom. When a tab that can be made
//   phantom is closed the renderer is shutdown, a new
//   CTTabContents/NavigationController is created that has not yet loaded the
//   renderer and observers are notified via the TabReplacedAt method. When a
//   phantom tab is selected the renderer is loaded and the tab is no longer
//   phantom.
//   Phantom tabs do not prevent the tabstrip from closing, for example if the
//   tabstrip has one phantom and one non-phantom tab and the non-phantom tab is
//   closed, then the tabstrip/browser are closed.
//
//  A TabStripModel has one delegate that it relies on to perform certain tasks
//  like creating new TabStripModels (probably hosted in CTBrowser windows) when
//  required. See TabStripDelegate above for more information.
//
//  A TabStripModel also has N observers (see TabStripModelObserver above),
//  which can be registered via Add/RemoveObserver. An Observer is notified of
//  tab creations, removals, moves, and other interesting events. The
//  TabStrip implements this interface to know when to create new tabs in
//  the View, and the CTBrowser object likewise implements to be able to update
//  its bookkeeping when such events happen.
//
////////////////////////////////////////////////////////////////////////////////
class CTTabStripModel /*: public NotificationObserver*/ {
 public:
  // Policy for how new tabs are inserted.
  enum InsertionPolicy {
    // Newly created tabs are created after the selection. This is the default.
    INSERT_AFTER,

    // Newly created tabs are inserted before the selection.
    INSERT_BEFORE,
  };

  // Used to specify what should happen when the tab is closed.
  enum CloseTypes {
    CLOSE_NONE                     = 0,

    // Indicates the tab was closed by the user. If true,
    // CTTabContents::set_closed_by_user_gesture(true) is invoked.
    CLOSE_USER_GESTURE             = 1 << 0,

    // If true the history is recorded so that the tab can be reopened later.
    // You almost always want to set this.
    CLOSE_CREATE_HISTORICAL_TAB    = 1 << 1,
  };

  // Constants used when adding tabs.
  enum AddTabTypes {
    // Used to indicate nothing special should happen to the newly inserted
    // tab.
    ADD_NONE          = 0,

    // The tab should be selected.
    ADD_SELECTED      = 1 << 0,

    // The tab should be pinned.
    ADD_PINNED        = 1 << 1,

    // If not set the insertion index of the CTTabContents is left up to the Order
    // Controller associated, so the final insertion index may differ from the
    // specified index. Otherwise the index supplied is used.
    ADD_FORCE_INDEX   = 1 << 2,

    // If set the newly inserted tab inherits the group of the currently
    // selected tab. If not set the tab may still inherit the group under
    // certain situations.
    ADD_INHERIT_GROUP = 1 << 3,

    // If set the newly inserted tab's opener is set to the currently selected
    // tab. If not set the tab may still inherit the group/opener under certain
    // situations.
    // NOTE: this is ignored if ADD_INHERIT_GROUP is set.
    ADD_INHERIT_OPENER = 1 << 4,
  };

  static const int kNoTab = -1;

  // Construct a TabStripModel with a delegate to help it do certain things
  // (See CTTabStripModelDelegate documentation). |delegate| cannot be NULL.
  CTTabStripModel(NSObject<CTTabStripModelDelegate>* delegate);
  virtual ~CTTabStripModel();

  // Retrieves the CTTabStripModelDelegate associated with this TabStripModel.
  NSObject<CTTabStripModelDelegate>* delegate() const { return delegate_; }

  // Add and remove observers to changes within this TabStripModel.
  void AddObserver(CTTabStripModelObserver* observer);
  void RemoveObserver(CTTabStripModelObserver* observer);

  // Retrieve the number of CTTabContentses/emptiness of the TabStripModel.
  int count() const { return static_cast<int>(contents_data_.size()); }
  bool empty() const { return contents_data_.empty(); }

  // Returns true if there are any non-phantom tabs. When there are no
  // non-phantom tabs the delegate is notified by way of TabStripEmpty and the
  // browser closes.
  bool HasNonPhantomTabs() const;

  // Retrieve the Profile associated with this TabStripModel.
  //Profile* profile() const { return profile_; }

  // Retrieve the index of the currently selected CTTabContents.
  int selected_index() const { return selected_index_; }

  // Returns true if the tabstrip is currently closing all open tabs (via a
  // call to CloseAllTabs). As tabs close, the selection in the tabstrip
  // changes which notifies observers, which can use this as an optimization to
  // avoid doing meaningless or unhelpful work.
  bool closing_all() const { return closing_all_; }

  // Access the order controller. Exposed only for unit tests.
  CTTabStripModelOrderController* order_controller() const {
    return order_controller_;
  }

  // Sets the insertion policy. Default is INSERT_AFTER.
  void SetInsertionPolicy(InsertionPolicy policy);
  InsertionPolicy insertion_policy() const;

  // Returns true if |observer| is in the list of observers. This is intended
  // for debugging.
  bool HasObserver(CTTabStripModelObserver* observer);

  // Basic API /////////////////////////////////////////////////////////////////

  // Determines if the specified index is contained within the TabStripModel.
  bool ContainsIndex(int index) const;

  // Adds the specified CTTabContents in the default location. Tabs opened in the
  // foreground inherit the group of the previously selected tab.
  void AppendTabContents(CTTabContents* contents, bool foreground);

  // Adds the specified CTTabContents at the specified location. |add_types| is a
  // bitmask of AddTypes; see it for details.
  //
  // All append/insert methods end up in this method.
  //
  // NOTE: adding a tab using this method does NOT query the order controller,
  // as such the ADD_FORCE_INDEX AddType is meaningless here.  The only time the
  // |index| is changed is if using the index would result in breaking the
  // constraint that all mini-tabs occur before non-mini-tabs.
  // See also AddTabContents.
  void InsertTabContentsAt(int index,
                           CTTabContents* contents,
                           int add_types);

  // Closes the CTTabContents at the specified index. This causes the CTTabContents
  // to be destroyed, but it may not happen immediately (e.g. if it's a
  // CTTabContents). |close_types| is a bitmask of CloseTypes.
  // Returns true if the CTTabContents was closed immediately, false if it was not
  // closed (we may be waiting for a response from an onunload handler, or
  // waiting for the user to confirm closure).
  bool CloseTabContentsAt(int index, uint32 close_types);

  // Replaces the entire state of a the tab at index by switching in a
  // different NavigationController. This is used through the recently
  // closed tabs list, which needs to replace a tab's current state
  // and history with another set of contents and history.
  //
  // The old NavigationController is deallocated and this object takes
  // ownership of the passed in controller.
  //void ReplaceNavigationControllerAt(int index,
  //                                   NavigationController* controller);

  // Replaces the tab contents at |index| with |new_contents|. |type| is passed
  // to the observer. This deletes the CTTabContents currently at |index|.
  void ReplaceTabContentsAt(int index,
                            CTTabContents* new_contents,
                            CTTabReplaceType type);

  // Detaches the CTTabContents at the specified index from this strip. The
  // CTTabContents is not destroyed, just removed from display. The caller is
  // responsible for doing something with it (e.g. stuffing it into another
  // strip).
  CTTabContents* DetachTabContentsAt(int index);

  // Select the CTTabContents at the specified index. |user_gesture| is true if
  // the user actually clicked on the tab or navigated to it using a keyboard
  // command, false if the tab was selected as a by-product of some other
  // action.
  void SelectTabContentsAt(int index, bool user_gesture);

  // Move the CTTabContents at the specified index to another index. This method
  // does NOT send Detached/Attached notifications, rather it moves the
  // CTTabContents inline and sends a Moved notification instead.
  // If |select_after_move| is false, whatever tab was selected before the move
  // will still be selected, but it's index may have incremented or decremented
  // one slot.
  // NOTE: this does nothing if the move would result in app tabs and non-app
  // tabs mixing.
  void MoveTabContentsAt(int index, int to_position, bool select_after_move);

  // Returns the currently selected CTTabContents, or NULL if there is none.
  CTTabContents* GetSelectedTabContents() const;

  // Returns the CTTabContents at the specified index, or NULL if there is none.
  CTTabContents* GetTabContentsAt(int index) const;

  // Returns the index of the specified CTTabContents, or CTTabContents::kNoTab if
  // the CTTabContents is not in this TabStripModel.
  int GetIndexOfTabContents(const CTTabContents* contents) const;

  // Returns the index of the specified NavigationController, or -1 if it is
  // not in this TabStripModel.
  //int GetIndexOfController(const NavigationController* controller) const;

  // Notify any observers that the CTTabContents at the specified index has
  // changed in some way. See TabChangeType for details of |change_type|.
  void UpdateTabContentsStateAt(
      int index,
      CTTabChangeType change_type);

  // Make sure there is an auto-generated New Tab tab in the TabStripModel.
  // If |force_create| is true, the New Tab will be created even if the
  // preference is set to false (used by startup).
  void EnsureNewTabVisible(bool force_create);

  // Close all tabs at once. Code can use closing_all() above to defer
  // operations that might otherwise by invoked by the flurry of detach/select
  // notifications this method causes.
  void CloseAllTabs();

  // Returns true if there are any CTTabContents that are currently loading.
  bool TabsAreLoading() const;

  // Returns the controller controller that opened the CTTabContents at |index|.
  //NavigationController* GetOpenerOfTabContentsAt(int index);

  // Returns the index of the next CTTabContents in the sequence of CTTabContentses
  // spawned by the specified NavigationController after |start_index|.
  // If |use_group| is true, the group property of the tab is used instead of
  // the opener to find the next tab. Under some circumstances the group
  // relationship may exist but the opener may not.
  // NOTE: this skips phantom tabs.
  //int GetIndexOfNextTabContentsOpenedBy(const NavigationController* opener,
  //                                      int start_index,
  //                                      bool use_group) const;

  // Returns the index of the first CTTabContents in the model opened by the
  // specified opener.
  // NOTE: this skips phantom tabs.
  //int GetIndexOfFirstTabContentsOpenedBy(const NavigationController* opener,
  //                                       int start_index) const;

  // Returns the index of the last CTTabContents in the model opened by the
  // specified opener, starting at |start_index|.
  // NOTE: this skips phantom tabs.
  //int GetIndexOfLastTabContentsOpenedBy(const NavigationController* opener,
  //                                      int start_index) const;

  // Called by the CTBrowser when a navigation is about to occur in the specified
  // CTTabContents. Depending on the tab, and the transition type of the
  // navigation, the TabStripModel may adjust its selection and grouping
  // behavior.
  void TabNavigating(CTTabContents* contents, CTPageTransition transition);

  // Forget all Opener relationships that are stored (but _not_ group
  // relationships!) This is to reduce unpredictable tab switching behavior
  // in complex session states. The exact circumstances under which this method
  // is called are left up to the implementation of the selected
  // CTTabStripModelOrderController.
  void ForgetAllOpeners();

  // Forgets the group affiliation of the specified CTTabContents. This should be
  // called when a CTTabContents that is part of a logical group of tabs is
  // moved to a new logical context by the user (e.g. by typing a new URL or
  // selecting a bookmark). This also forgets the opener, which is considered
  // a weaker relationship than group.
  void ForgetGroup(CTTabContents* contents);

  // Returns true if the group/opener relationships present for |contents|
  // should be reset when _any_ selection change occurs in the model.
  bool ShouldResetGroupOnSelect(CTTabContents* contents) const;

  // Changes the blocked state of the tab at |index|.
  void SetTabBlocked(int index, bool blocked);

  // Changes the pinned state of the tab at |index|. See description above
  // class for details on this.
  void SetTabPinned(int index, bool pinned);

  // Returns true if the tab at |index| is pinned.
  // See description above class for details on pinned tabs.
  bool IsTabPinned(int index) const;

  // Is the tab a mini-tab?
  // See description above class for details on this.
  bool IsMiniTab(int index) const;

  // Is the tab at |index| an app?
  // See description above class for details on app tabs.
  bool IsAppTab(int index) const;

  // Returns true if the tab is a phantom tab. A phantom tab is one where the
  // renderer has not been loaded.
  // See description above class for details on phantom tabs.
  bool IsPhantomTab(int index) const;

  // Returns true if the tab at |index| is blocked by a tab modal dialog.
  bool IsTabBlocked(int index) const;

  // Returns the index of the first tab that is not a mini-tab. This returns
  // |count()| if all of the tabs are mini-tabs, and 0 if none of the tabs are
  // mini-tabs.
  int IndexOfFirstNonMiniTab() const;

  // Returns a valid index for inserting a new tab into this model. |index| is
  // the proposed index and |mini_tab| is true if inserting a tab will become
  // mini (pinned or app). If |mini_tab| is true, the returned index is between
  // 0 and IndexOfFirstNonMiniTab. If |mini_tab| is false, the returned index
  // is between IndexOfFirstNonMiniTab and count().
  int ConstrainInsertionIndex(int index, bool mini_tab);

  // Returns the index of the first tab that is not a phantom tab. This returns
  // kNoTab if all of the tabs are phantom tabs.
  int IndexOfFirstNonPhantomTab() const;

  // Returns the number of non phantom tabs in the TabStripModel.
  int GetNonPhantomTabCount() const;


  // Command level API /////////////////////////////////////////////////////////

  // Adds a CTTabContents at the best position in the TabStripModel given the
  // specified insertion index, transition, etc. |add_types| is a bitmask of
  // AddTypes; see it for details. This method ends up calling into
  // InsertTabContentsAt to do the actual inertion.
  int AddTabContents(CTTabContents* contents,
                     int index,
                     CTPageTransition transition,
                     int add_types);

  // Closes the selected CTTabContents.
  void CloseSelectedTab();

  // Select adjacent tabs
  void SelectNextTab();
  void SelectPreviousTab();

  // Selects the last tab in the tab strip.
  void SelectLastTab();

  // Swap adjacent tabs.
  void MoveTabNext();
  void MoveTabPrevious();

  // View API //////////////////////////////////////////////////////////////////

  // Context menu functions.
  enum ContextMenuCommand {
    CommandFirst = 0,
    CommandNewTab,
    CommandReload,
    CommandDuplicate,
    CommandCloseTab,
    CommandCloseOtherTabs,
    CommandCloseTabsToRight,
    CommandRestoreTab,
    CommandTogglePinned,
    CommandBookmarkAllTabs,
    CommandUseVerticalTabs,
    CommandLast
  };

  // Returns true if the specified command is enabled.
  bool IsContextMenuCommandEnabled(int context_index,
                                   ContextMenuCommand command_id) const;

  // Returns true if the specified command is checked.
  bool IsContextMenuCommandChecked(int context_index,
                                   ContextMenuCommand command_id) const;

  // Performs the action associated with the specified command for the given
  // TabStripModel index |context_index|.
  void ExecuteContextMenuCommand(int context_index,
                                 ContextMenuCommand command_id);

  // Returns a vector of indices of the tabs that will close when executing the
  // command |id| for the tab at |index|. The returned indices are sorted in
  // descending order.
  std::vector<int> GetIndicesClosedByCommand(int index,
                                             ContextMenuCommand id) const;

  // Overridden from notificationObserver:
  /*virtual void Observe(NotificationType type,
                       const NotificationSource& source,
                       const NotificationDetails& details);*/
  // TODO replace with NSNotification if possible:
  void TabContentsWasDestroyed(CTTabContents *contents);

 private:
  // We cannot be constructed without a delegate.
  CTTabStripModel();

  // Returns true if the specified CTTabContents is a New Tab at the end of the
  // TabStrip. We check for this because opener relationships are _not_
  // forgotten for the New Tab page opened as a result of a New Tab gesture
  // (e.g. Ctrl+T, etc) since the user may open a tab transiently to look up
  // something related to their current activity.
  bool IsNewTabAtEndOfTabStrip(CTTabContents* contents) const;

  // Closes the CTTabContents at the specified indices. This causes the
  // CTTabContents to be destroyed, but it may not happen immediately.  If the
  // page in question has an unload event the CTTabContents will not be destroyed
  // until after the event has completed, which will then call back into this
  // method.
  //
  // Returns true if the CTTabContents were closed immediately, false if we are
  // waiting for the result of an onunload handler.
  bool InternalCloseTabs(const std::vector<int>& indices, uint32 close_types);

  // Invoked from InternalCloseTabs and when an extension is removed for an app
  // tab. Notifies observers of TabClosingAt and deletes |contents|. If
  // |create_historical_tabs| is true, CreateHistoricalTab is invoked on the
  // delegate.
  //
  // The boolean parameter create_historical_tab controls whether to
  // record these tabs and their history for reopening recently closed
  // tabs.
  void InternalCloseTab(CTTabContents* contents,
                        int index,
                        bool create_historical_tabs);

  CTTabContents* GetContentsAt(int index) const;

  // The actual implementation of SelectTabContentsAt. Takes the previously
  // selected contents in |old_contents|, which may actually not be in
  // |contents_| anymore because it may have been removed by a call to say
  // DetachTabContentsAt...
  void ChangeSelectedContentsFrom(
      CTTabContents* old_contents, int to_index, bool user_gesture);

  // Returns the number of New Tab tabs in the TabStripModel.
  int GetNewTabCount() const;

  // Selects either the next tab (|foward| is true), or the previous tab
  // (|forward| is false).
  void SelectRelativeTab(bool forward);

  // Returns the first non-phantom tab starting at |index|, skipping the tab at
  // |ignore_index|.
  int IndexOfNextNonPhantomTab(int index, int ignore_index);

  // Returns true if the tab at the specified index should be made phantom when
  // the tab is closing.
  bool ShouldMakePhantomOnClose(int index);

  // Makes the tab a phantom tab.
  void MakePhantom(int index);

  // Does the work of MoveTabContentsAt. This has no checks to make sure the
  // position is valid, those are done in MoveTabContentsAt.
  void MoveTabContentsAtImpl(int index,
                             int to_position,
                             bool select_after_move);

  // Returns true if the tab represented by the specified data has an opener
  // that matches the specified one. If |use_group| is true, then this will
  // fall back to check the group relationship as well.
  struct TabContentsData;
  //static bool OpenerMatches(const TabContentsData* data,
  //                          const NavigationController* opener,
  //                          bool use_group);

  // Does the work for ReplaceTabContentsAt returning the old CTTabContents.
  // The caller owns the returned CTTabContents.
  CTTabContents* ReplaceTabContentsAtImpl(
      int index,
      CTTabContents* new_contents,
      CTTabReplaceType type);

  // Our delegate.
  /* bug! __weak */ NSObject<CTTabStripModelDelegate>* delegate_;

  // A hunk of data representing a CTTabContents and (optionally) the
  // NavigationController that spawned it. This memory only sticks around while
  // the CTTabContents is in the current TabStripModel, unless otherwise
  // specified in code.
  struct TabContentsData {
    explicit TabContentsData(CTTabContents* a_contents)
        : contents(a_contents),
          //reset_group_on_select(false),
          pinned(false),
          blocked(false) {
      //SetGroup(NULL);
    }

    // Create a relationship between this CTTabContents and other CTTabContentses.
    // Used to identify which CTTabContents to select next after one is closed.
    //void SetGroup(NavigationController* a_group) {
    //  group = a_group;
    //  opener = a_group;
    //}

    // Forget the opener relationship so that when this CTTabContents is closed
    // unpredictable re-selection does not occur.
    void ForgetOpener() {
      //opener = NULL;
    }

    CTTabContents* contents; // weak
    // We use NavigationControllers here since they more closely model the
    // "identity" of a Tab, CTTabContents can change depending on the URL loaded
    // in the Tab.
    // The group is used to model a set of tabs spawned from a single parent
    // tab. This value is preserved for a given tab as long as the tab remains
    // navigated to the link it was initially opened at or some navigation from
    // that page (i.e. if the user types or visits a bookmark or some other
    // navigation within that tab, the group relationship is lost). This
    // property can safely be used to implement features that depend on a
    // logical group of related tabs.
    //NavigationController* group;
    // The owner models the same relationship as group, except it is more
    // easily discarded, e.g. when the user switches to a tab not part of the
    // same group. This property is used to determine what tab to select next
    // when one is closed.
    //NavigationController* opener;
    // True if our group should be reset the moment selection moves away from
    // this Tab. This is the case for tabs opened in the foreground at the end
    // of the TabStrip while viewing another Tab. If these tabs are closed
    // before selection moves elsewhere, their opener is selected. But if
    // selection shifts to _any_ tab (including their opener), the group
    // relationship is reset to avoid confusing close sequencing.
    //bool reset_group_on_select;

    // Is the tab pinned?
    bool pinned;

    // Is the tab interaction blocked by a modal dialog?
    bool blocked;
  };

  // The CTTabContents data currently hosted within this TabStripModel.
  typedef std::vector<TabContentsData*> TabContentsDataVector;
  TabContentsDataVector contents_data_;

  // The index of the CTTabContents in |contents_| that is currently selected.
  int selected_index_;

  // A profile associated with this TabStripModel, used when creating new Tabs.
  //Profile* profile_;

  // True if all tabs are currently being closed via CloseAllTabs.
  bool closing_all_;

  // An object that determines where new Tabs should be inserted and where
  // selection should move when a Tab is closed.
  CTTabStripModelOrderController* order_controller_;

  // Our observers.
  typedef ObserverList<CTTabStripModelObserver> TabStripModelObservers;
  TabStripModelObservers observers_;

  // A scoped container for notification registries.
  //NotificationRegistrar registrar_;

  DISALLOW_COPY_AND_ASSIGN(CTTabStripModel);
};

#endif  // CHROME_BROWSER_TABS_TAB_STRIP_MODEL_H_
