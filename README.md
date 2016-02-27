# Hive

Hive is a user-friendly Bitcoin wallet app for OSX.

![](http://i.imgur.com/p5VoeND.png)


## Status

Hive development has stopped and it's not being maintained anymore. There are no plans for any further updates or bug fixes.

The app still works in the current state, because it doesn't rely on any server-side components managed by Hive, but it might stop working after a breaking change in the Bitcoin protocol, and it will almost certainly stop working on the next version of OS X which drops support for old Java. It's recommended that you migrate your funds to a different wallet.


## Requirements

* OSX 10.7 (Lion) or newer, up to 10.11 (10.12 will not be supported)
* [Apple Java runtime](https://support.apple.com/kb/DL1572)


## Building

First, clone the GitHub repository:

    git clone git@github.com:hivewallet/hive-mac.git

Make sure you have CocoaPods installed:

    gem install cocoapods

Install the required pods:

    pod install

Now, import some Hive libraries which are kept in separate repositories as submodules:

    git submodule update --init --recursive

Before you build the project, you also need to install some additional libraries using homebrew:

    brew install libevent openssl maven
    brew link openssl --force

Then you can open the project workspace in Xcode (`Hive.xcworkspace`, not `Hive.xcodeproj`), hit the Run button and wait for it to build. Enjoy!

Note: the Xcode build is configured to use Hive certificates, so you'll probably need to disable code signing to make it build without them.


## Test vs. production network

Hive is currently set up to use the main blockchain. If you prefer to use the testing network to avoid risking real Bitcoin while testing the app, change the line `#define TESTING_NETWORK 0` in `Hive-Prefix.pch` to `1` and rebuild the app or launch it with the `Hive (Test Network)` scheme in Xcode.


## Contributing

Patches and pull requests are very welcome. If you want to send us any code, read the [Coding guidelines](https://github.com/hivewallet/hive-mac/wiki/Code-style-guidelines) first.

Hive code is dual-licensed: we've released it under GPL v2 (see below), however we reserve a right to relicense it under a different license in future (including a commercial one), since we might want to e.g. put it on Mac or iOS App Store, or use it for other purposes with which GPL is incompatible. Because of that, we ask that you specify a more permissive license for your code when you submit a patch to us (e.g. MIT, WTFPL or public domain).

If you like Hive OSX, you can also send us donations in BTC to: 1wdERgJVZhqeUVTWGmZqdorLGtFVzF1xy.


## License

Hive is released under GNU General Public License, version 2 or later.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
