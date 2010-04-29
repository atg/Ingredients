#!/usr/bin/osascript

tell application "Ingredients"
	search front window query "%%%{PBXSelectedText}%%%"
end tell
