# Introduction #

The page lists known issues with the project.

# Known Issues #

## Screenshot Command does not work on mac ##

Issue [#1](http://code.google.com/p/commandproxy/issues/detail?id=1)

The screenshot command currently does not work on Mac, and fails with the following error:

`Error taking screenshot`

The underlying error message is:

`An exception was thrown by the type initializer for System.Windows.Forms.Screen`

This appears to be an issue with the mono framework /  runtime.