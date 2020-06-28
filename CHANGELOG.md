Comment Boss 1.0(2) 2017-06-04
Initial App Store release candidate.
Comment rows no longer ends with space as the last character.
Line breaks correctly line up with Xcode's Page Guide at Column setting.
Application terminates when closing the app window.

Comment Boss 1.0β(1) 2017-05-21
Initial beta release.
Using Swift 3.


### Ideas for behavior changes:

* When the comment is deemed to be too close to the end of the line, yank it and put it on the previous line.
https://www.emacswiki.org/emacs/CodeBeautifying
* Handle all lines in a selection, probably looping from the last to the first to not screw up line indexing too badly when inserting new lines. If a line contains a comment, handle it. Otherwise move on.
