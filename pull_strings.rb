#!/usr/bin/env ruby

def process_file(file)
  File.write(file, %x(iconv -f UTF-16 -t UTF-8 #{file}))
end

IO.popen("tx pull #{ARGV.join(' ')}") do |io|
  last_file = nil

  io.each_line do |line|
    print line
    if line =~ /->/
      process_file(last_file) if last_file
      last_file = line.split(' ').last
    end
  end

  process_file(last_file) if last_file
end
