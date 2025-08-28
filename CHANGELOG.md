## 0.2.0

- Stripped out the generics implementation. Dart just isn't up to the task of strongly typing input from form files using the field<Type> syntax. We went back to dynamic dispatch and then rely on validator functions to make sure output is appropriate for the use case.

- Updated example application to properly utilize the default validators.

- Pushed dependency version numbers to latest releases.

## 0.0.4

Killed Riverpod as a dependency for this library. I love Riverpod, but it wasn't being used correctly here.
Now the library can function with any (or no) state management using the new ChampionFormController.

Removed formIds since we have a controller serving that purpose.

Most things should continue to operate the same, just no more need for riverpod.

Fixing the readme. It needs a little bit of love to fix a few errors.

## 0.0.3

Major overhaul of the entire library. Open sourced (yay!).

Library launches with support for text fields / text areas. As well as option select in the form of dropdown and checkboxes.

Added themes as well as having it default to app theme colors from Material widget.

This is a brand new release and is still very much an alpha product.


## 0.0.1

* TODO: Describe initial release.
