require 'sequel'
require 'zlib'
require 'stringio'

SIZE_THRESHOLD = 100
PERCENTAGE_THRESHOLD = 1
def show(stat, count)
  print "at count #{count}\n"
  stat.keys.sort{|a, b| stat[b] <=> stat[a]}.each {|k|
    percentage = (stat[k] * 100.0 / count).round
    break if percentage <= PERCENTAGE_THRESHOLD
    print "#{k}: #{stat[k]} (#{percentage}%)\n"
  }
  print "---\n"
end

stat = Hash.new{|h, k| h[k] = 0}
count = 0
DB = Sequel.sqlite('/export/openmaptiles/africa.mbtiles')
DB[:tiles].each {|r|
  (z, x, y) = [
    r[:zoom_level], r[:tile_column], (1 << r[:zoom_level]) - r[:tile_row] - 1
  ]
  data = Zlib::GzipReader.new(StringIO.new(r[:tile_data])).read
  next if data.size < SIZE_THRESHOLD
  count += 1
  stat[data.size / 1000 * 1000] += 1
  show(stat, count) if count % 10000 == 0
  #print "#{z}/#{x}/#{y}: #{data.size}bytes\n"
}
show(stat, count)
