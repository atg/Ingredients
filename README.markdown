Ingredients is a documentation viewer for Cocoa. It's designed to replace the one that comes with Xcode (try searching for "NSStr" and count how many items are above "NSString").

![Ingredients's main window](http://www.fileability.net/snaps/ing6.png)

## System Requirements
Requires the latest version of OS X. We may require a major OS update on a point release, depending on how juicy the new developer features are. For now though it looks like you're safe, since Apple is totally ignoring Mac OS X.

We do aggressive caching, so make sure you have lots of RAM (usage seems to be around 100MB at this point).

## Build Instructions
You will need to have the BWToolkit IB plugin installed. You can get it at <http://brandonwalkin.com/bwtoolkit/>.

Ingredients won't build using <span title="Oh god am I allowed to say that? Please don't sue me, Apple">Xcode 4</span> because Apple broke IB plugins.

If you see lots of warnings, you know it's built correctly.

## Licence

In protest to [recent FUD](http://www.fsf.org/blogs/licensing/vlc-enforcement) from the Free Software Foundation, Ingredients is now licensed under the BSD licence.