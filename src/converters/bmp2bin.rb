#!/usr/bin/env ruby

require 'RMagick'

file = ARGV[0]

img = Magick::Image::read(file).first
chars = []
line = ''

img.each_pixel do |pixel, x, y|
  if line.length == 8
    chars << line
    line = ''
  end
  if pixel.intensity > 32768
    line += '0'
  else
    line += '1'
  end
end

ordered_chars = []
for i in (0..255)
  char = []
  (0..4).each {|c| char << chars[c * 20 + ((i / 20) * 20 * 6) + i % 20]}
  char_width = 0
  char.each do |char_line|
    w = 7
    w -= 1 while char_line[w] == '0'
    char_width = [char_width, w].max
  end
  char.insert(0, char_width)
  ordered_chars << char
end

ordered_chars.each do |i|
  i.each_index do |j|
    if i[j].class == String
      i[j] = i[j].to_i(2)
    end
  end
end
ordered_chars = ordered_chars.first(127)

puts ordered_chars[-1]
File.open(ARGV[1], mode='w') do |f|
  f.write "unsigned char font =\n"
  f.write "{"
  ordered_chars.each do |ch|
    f << "\n"
    ch.each do |li|
      f << "0x" << li.to_s(16) << ", "
    end
  end
  f.pos -= 1
  f << "\n};"
end

