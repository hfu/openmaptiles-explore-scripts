require 'sequel'
require 'zlib'
require 'stringio'

MAX_ZOOM_ALL_IN = 10
BIN = 1000
SIZE_THRESHOLD = 500
PERCENTAGE_THRESHOLD = 1
PATH = '/export/openmaptiles/france.mbtiles'
def human(v) 
  %w{B KB MB GB}.each {|suffix|
    return v.ceil.to_s + suffix if v < 1024
    v = v / 1024.0
  }
end
def show
  print "#{File.basename(PATH)}(#{human(File.size(PATH))}) at count #{$count}\n"
  0.upto(14) {|z|
    next if $size_to_write[z] == 0
    print [
      z, human($size_to_write[z]), human($size_to_save[z]), 
      (100.0 * $size_to_write[z] / ($size_to_write[z] + $size_to_save[z])).round.
        to_s + '%'
    ].join("\t"), "\n"
  }
  print human($size_to_write.values.inject{|s, e| s += e}), " for all\n"
  $stat.keys.sort{|a, b| $stat[b] <=> $stat[a]}.each {|k|
    percentage = ($stat[k] * 100.0 / $count).round
    break if percentage <= PERCENTAGE_THRESHOLD
    print "#{k}: #{$stat[k]} (#{percentage}%)\n"
  }
  print "---\n"
end

$stat = Hash.new{|h, k| h[k] = 0}
$size_to_write = Hash.new{|h, z| h[z] = 0}
$size_to_save = Hash.new{|h, z| h[z] = 0}
$count = 0
DB = Sequel.sqlite(PATH)
DB[:tiles].each {|r|
  (z, x, y) = [
    r[:zoom_level], r[:tile_column], (1 << r[:zoom_level]) - r[:tile_row] - 1
  ]
  data = Zlib::GzipReader.new(StringIO.new(r[:tile_data])).read
  size = data.size
  $count += 1
  if z <= MAX_ZOOM_ALL_IN or size > SIZE_THRESHOLD
    $size_to_write[z] += size
    $stat[size / BIN * BIN] += 1
  else
    $size_to_save[z] += size
  end
  show if $count % 10000 == 0
}
show
