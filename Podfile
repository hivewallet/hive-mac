platform :osx, '10.9'

pod 'AFNetworking',       '~> 1.3.2'
pod 'AutoLayoutMacros'
pod 'Chain', '2.2.0pre2'
pod 'CocoaLumberjack'
pod 'CoreBitcoin'
pod 'FontAwesomeIconFactory'
pod 'INAppStoreWindow'
pod 'LetsMove'
pod 'ZXingObjC', '~> 2.2.8'  # 3.x requires 10.8+
pod 'Sparkle'
pod 'MASPreferences'
pod 'MASShortcut'
pod 'NSURL+Gravatar'

target :test, :exclusive => true do
  link_with 'HiveTests'
  pod 'Kiwi'
  pod 'OCHamcrest', '4.0'    # 4.0.1 requires 10.8+
end
