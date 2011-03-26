Ingredients is a documentation viewer for Cocoa. It's designed to replace the one that comes with Xcode (try searching for "NSStr" and count how many items are above "NSString").

![Ingredients's main window](http://www.fileability.net/snaps/ing6.png)

## System Requirements
Requires the latest version of OS X. We may require a major OS update on a point release, depending on how juicy the new developer features are. Currently works on 10.6 or later.

We do lots of caching, so make sure you have lots of RAM (usage seems to be around 100MB at this point). Developers all have > 4GB, right?

## Build Instructions
You will need to have the BWToolkit IB plugin installed. You can get it at <http://brandonwalkin.com/bwtoolkit/>.

Ingredients might not build under Xcode 4 because Apple broke IB plugins. You'll need to install BWToolkit for it.

If you see lots of warnings, you know it's built correctly.

## Licence
Ingredients is licensed under the under the [Chicken Dance License](https://github.com/supertunaman/cdl).