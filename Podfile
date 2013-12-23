platform :osx, '10.7'

pod 'INAppStoreWindow'
pod 'AFNetworking',       '~> 1.3.2'
pod 'NXOAuth2Client'
pod 'FXKeychain'
pod 'CocoaLumberjack'
pod 'LetsMove'

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
