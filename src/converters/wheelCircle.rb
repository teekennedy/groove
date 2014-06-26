#!/usr/bin/env ruby


File.open(ARGV[0], mode='w') do |f|
  f << "unsigned char song_wheel_lookup_table[] =\n{\n"
  (0..49).each do |y|
    x = (y - 42)**2
    x = 4900 - x
    x = x.abs
    x = Math.sqrt(x)
    x = 150 - x

    f << x.round.to_s
    f << ", " unless y == 49
    f << "\n" if y % 5 == 4
  end
  f << "};\n"
end

