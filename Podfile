platform :osx, '10.7'

pod 'AFNetworking',       '~> 1.3.2'
pod 'AutoLayoutMacros'
pod 'CocoaLumberjack'
pod 'FontAwesomeIconFactory'
pod 'INAppStoreWindow'
pod 'LetsMove'
pod 'ZXingObjC', '~> 2.2.8'  # 3.x requires 10.8+
pod 'Sparkle-pornel'
pod 'MASPreferences'
pod 'MASShortcut'
pod 'NSURL+Gravatar'

target :test, :exclusive => true do
  link_with 'HiveTests'
  pod 'Kiwi/XCTest'
  pod 'OCHamcrest', '~> 3.0'
end

# Map old locale names (used in LetsMove) to ours
pre_install do |installer|
  locale_mapping = {
    "danish" => "da",
    "dutch" => "nl",
    "english" => "en",
    "french" => "fr",
    "german" => "de",
    "italian" => "it",
    "japanese" => "ja",
    "portuguese" => "pt",
    "russian" => "ru",
    "spanish" => "es",
  }

  installer.pods.each do |pod|
    %x[ find "#{pod.root}" -name '*.lproj' ].split.each do |bundle|
      locale = File.basename(bundle, ".lproj").downcase
      if locale_mapping.has_key?(locale)
        newLocaleName = locale_mapping[locale]
        newBundleName = File.join(File.dirname(bundle), newLocaleName + ".lproj")
        FileUtils.mv(bundle, newBundleName)
      end
    end
  end
end
