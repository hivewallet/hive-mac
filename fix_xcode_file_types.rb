#!/usr/bin/env ruby

file = 'Hive.xcodeproj/project.pbxproj'
source = File.read(file)

File.open(file, 'w') do |f|
  source.each_line do |line|
    if line =~ /lastKnownFileType = file;/
      if line =~ /\.xib"?;/
        line.gsub!(/lastKnownFileType = file;/, 'lastKnownFileType = file.xib;')
      elsif line =~ /\.strings"?;/
        line.gsub!(/lastKnownFileType = file;/, 'lastKnownFileType = text.plist.strings;')
      end
    end

    f.print(line)
  end
end
