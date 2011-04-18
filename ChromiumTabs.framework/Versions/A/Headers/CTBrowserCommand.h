#ifndef CT_BROWSER_COMMAND_H_
#define CT_BROWSER_COMMAND_H_
#pragma once

// NOTE: Within each of the following sections, the IDs are ordered roughly by
// how they appear in the GUI/menus (left to right, top to bottom, etc.).

// NOTE: MainMenu.xib use these constants so if you change something here you
// also need to update the corresponding "tag" in MainMenu.xib

typedef enum {
  // Window management commands
  CTBrowserCommandNewWindow                 = 34000,
  //CTBrowserCommandNewIncognitoWindow       = 34001,
  CTBrowserCommandCloseWindow               = 34012,
  //CTBrowserCommandAlwaysOnTop              = 34013,
  CTBrowserCommandNewTab                    = 34014,
  CTBrowserCommandCloseTab                  = 34015,
  CTBrowserCommandSelectNextTab             = 34016,
  CTBrowserCommandSelectPreviousTab         = 34017,
  CTBrowserCommandSelectTab0                = 34018,
  CTBrowserCommandSelectTab1                = 34019,
  CTBrowserCommandSelectTab2                = 34020,
  CTBrowserCommandSelectTab3                = 34021,
  CTBrowserCommandSelectTab4                = 34022,
  CTBrowserCommandSelectTab5                = 34023,
  CTBrowserCommandSelectTab6                = 34024,
  CTBrowserCommandSelectTab7                = 34025,
  CTBrowserCommandSelectLastTab             = 34026,
  CTBrowserCommandDuplicateTab              = 34027,
  CTBrowserCommandRestoreTab                = 34028,
  CTBrowserCommandShowAsTab                 = 34029,
  CTBrowserCommandFullscreen                = 34030,
  CTBrowserCommandExit                      = 34031,
  CTBrowserCommandMoveTabNext               = 34032,
  CTBrowserCommandMoveTabPrevious           = 34033,
  //CTBrowserCommandToggleVerticalTabs        = 34034,
  //CTBrowserCommandSearch                    = 34035,
  //CTBrowserCommandTabpose                   = 34036,
} CTBrowserCommand;

#endif // CT_BROWSER_COMMAND_H_
