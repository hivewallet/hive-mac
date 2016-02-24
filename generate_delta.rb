#!/usr/bin/env ruby

require 'json'
require 'open-uri'
require 'time'

HIVE_TMP_FOLDER = "/tmp/HiveReleases"

if ARGV.length != 2
  puts "Usage: #{$PROGRAM_NAME} <new_version> <old_version>"
  exit 1
end

new_version, old_version = ARGV

if File.exist?(HIVE_TMP_FOLDER)
  if File.directory?(HIVE_TMP_FOLDER)
    puts "Error: #{HIVE_TMP_FOLDER} is not a directory."
    exit 1
  end
else
  File.mkdir(HIVE_TMP_FOLDER)
end



local_zip_file = File.expand_path(local_zip_file)
zip_size = File.size(local_zip_file)

json = JSON.parse(open("https://api.github.com/repos/hivewallet/hive-osx/releases").read)
release = json.detect { |r| r['tag_name'] == version }

unless release
  puts "Error: Release #{version} not found on GitHub."
  exit 1
end

date = Time.parse(release['published_at']).rfc822
release_notes = release['body'].gsub(/\- (.*?)\r\n/, "              <li>\\1</li>\n").strip
zip_asset = release['assets'].detect { |a| a['content_type'] == 'application/zip' }

unless zip_asset
  puts "Error: Release #{version} has no zip file uploaded."
  exit 1
end

zip_url = "https://github.com/hivewallet/hive-osx/releases/download/#{version}/#{zip_asset['name']}"

puts %(
<item>
    <title>Hive #{version}</title>
    <description>
        <![CDATA[
            <style type="text/css">
              h2 { font-family: Helvetica; font-weight: bold; font-size: 10pt; }
              ul { font-family: Helvetica; font-size: 10pt; }
              li { margin: 5px 0px; }
            </style>

            <h2>What's changed:</h2>

            <ul>
              #{release_notes}
            </ul>
        ]]>
    </description>
    <pubDate>#{date}</pubDate>
    <enclosure
      url="#{zip_url}"
      sparkle:version="#{build}"
      sparkle:shortVersionString="#{version}"
      length="#{zip_size}"
      type="application/octet-stream" />
    <sparkle:deltas>
      <enclosure
        url="#{delta_url}"
        sparkle:version="#{build}"
        sparkle:deltaFrom="#{previousBuild}"
        length="#{delta_size}"
        type="application/octet-stream" />
    </sparkle:deltas>
</item>
)
