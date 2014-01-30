#!/usr/bin/env ruby

if ARGV.length < 3
  puts "#{$PROGRAM_NAME} <source_filename> <source_title> <target_filename> [<target_title>]"
  exit 1
end

source_filename, source_title, target_filename, target_title = ARGV
target_title ||= source_title

langs = Dir['Hive/*.lproj'].map { |path| File.basename(path) }.reject { |dir| dir == 'en.lproj' }

langs.each do |lang|
  source_file = if File.exist?("Hive/#{lang}/#{source_filename}")
    "Hive/#{lang}/#{source_filename}"
  elsif File.exist?("Hive/Controllers/#{lang}/#{source_filename}")
    "Hive/Controllers/#{lang}/#{source_filename}"
  end

  target_file = if File.exist?("Hive/#{lang}/#{target_filename}")
    "Hive/#{lang}/#{target_filename}"
  elsif File.exist?("Hive/Controllers/#{lang}/#{target_filename}")
    "Hive/Controllers/#{lang}/#{target_filename}"
  end

  next unless source_file && target_file

  source = File.read(source_file)
  target = File.read(target_file)

  source_line = source.lines.map(&:strip).detect { |l| l.start_with?(%("#{source_title}")) }
  next unless source_line

  translation = source_line.scan(/"(.*?)"/)[1][0]
  target = target.gsub(/"#{target_title}" = ".*?";/, %("#{target_title}" = "#{translation}";))
  File.write(target_file, target)
end
