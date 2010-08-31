# OAuth2Client

A OAuth2 framework for Mac OS & iOS (Cocoa & Cocoa touch). It comes with the [JSON framework](http://github.com/stig/json-framework).

*README will be updated in the next days.*

## Quickstart

- git clone git://github.com/nxtbgthng/OAuth2Client.git
- cd OAuth2Client
- git submodule update --recursive --init

In your Xcode project:

- drag OAuth2Client.xcodeproj into your project
- add it as a build depedency
- add "/tmp/OAuth2Client.dst/usr/local/include" && "/tmp/JSON.dst/usr/local/include" to your user header search path in the build settings


## Known Issues

- only the iPhone library target is working atm