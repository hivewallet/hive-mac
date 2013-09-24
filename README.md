# Hive

Hive is a user-friendly Bitcoin wallet app for OSX.


## Requirements

* OSX 10.7 (Lion) or newer
* Java runtime (for now - required by bitcoinj lib)


## Building

First, clone the GitHub repository:

    git clone git@github.com:grabhive/hive-osx.git

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
