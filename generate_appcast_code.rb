#!/usr/bin/env ruby

require 'json'
require 'open-uri'
require 'time'

if ARGV.length < 3
  puts "Usage: #{$PROGRAM_NAME} <version> <local_zip_file> <private_key_file>"
  exit 1
end

version, local_zip_file, private_key_file = ARGV

local_zip_file = File.expand_path(local_zip_file)
file_size = File.size(local_zip_file)
signature = %x(./sign_update.rb #{local_zip_file} #{private_key_file}).gsub(/\s+/, '')

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
    <title>Hive 0.9 build #{version}</title>
    <description>
        <![CDATA[
            <p>What's changed:</p>

            <ul>
              #{release_notes}
            </ul>
        ]]>
    </description>
    <pubDate>#{date}</pubDate>
    <enclosure
    url="#{zip_url}"
    sparkle:version="#{version}"
    sparkle:shortVersionString="0.9"
    length="#{file_size}"
    type="application/octet-stream"
    sparkle:dsaSignature="#{signature}" />
</item>
)
