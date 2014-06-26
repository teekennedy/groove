#!/usr/bin/env ruby

Dir.foreach(ARGV[0]) do |f|
  next unless f.end_with?('.sm')
  #mess with path string to properly escape and handle spaces and double and single quotes.
  f.gsub!('"', '\"')
  f = '"' + ARGV[0] + '/' + f + '"'
  system "ruby sm2grv.rb -12345 #{f}"
end
