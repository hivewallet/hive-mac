#!/usr/bin/env ruby

BASE_DIRECTORIES = ['Hive', 'Hive/Controllers']


class StringsFile
  attr_reader :data

  def initialize(file)
    @data = {}

    File.read(file).scan(%r{/\* ([^*]+) \*/\n"(.+)" = "(.+)";\n+}) do |info, original, translated|
      @data[original] = { translated: translated, info: info }
    end
  end

  def update_from(source)
    rebuilt_data = {}

    source.data.keys.each do |key|
      old_data = @data[key]
      new_data = source.data[key]

      rebuilt_data[key] = {
        translated: (old_data ? old_data[:translated] : new_data[:translated]),
        info: new_data[:info]
      }
    end

    @data = rebuilt_data
  end

  def empty?
    @data.empty?
  end

  def to_s
    @data.map { |key, data|
      %(\n/* #{data[:info]} */\n"#{key}" = "#{data[:translated]}";\n)
    }.join
  end
end


BASE_DIRECTORIES.each do |base|
  Dir.glob("#{base}/en.lproj/*.strings").each do |file|
    filename = File.basename(file)
    puts "Updating translations of #{filename}..."

    original_data = StringsFile.new(file)

    Dir.glob("#{base}/*.lproj").each do |dir|
      next if File.basename(dir) == 'en.lproj'

      translated_file = "#{dir}/#{filename}"

      if File.exist?(translated_file)
        translated_data = StringsFile.new(translated_file)
        translated_data.update_from(original_data)

        if translated_data.empty?
          File.unlink(translated_file)
        else
          File.write(translated_file, translated_data)
        end
      end
    end
  end
end
