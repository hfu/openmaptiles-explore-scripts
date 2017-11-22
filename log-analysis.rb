require 'date'
require 'sequel'

def human(size)
	%w{B KB MB GB TB}.each {|s|
		return "#{size}#{s}" if size < 1024
		size /= 1024
	}
end

def download(l)
  r = l.strip.split('   ')
	date = DateTime.parse(r[0])
	size = r[1].split(' ')[0].to_i
  print "#{date.iso8601} pbf #{human(size)}\n"
end

def took(l)
	/\[INFO\] (.*) took: (.*)/.match l.strip
	%w{Generalizing Creating Rotating}.each {|v|
		return if $1.include?(v)
	}
	print "#{$1}\t#{$2}\n"
end

def speed(l)
	n = l.split('/s')[0].split(' ')[-1].to_i
  $count += 1
	$min = [$min, n].min
	$max = [$max, n].max
end

def stat
	print "min #{$min}, max #{$max}, count #{$count}\n\n"
end

def hundred(l)
	print "mapnik-tile-copy\t#{l.split(']')[0].split('[')[-1]}\n"
end

Dir.glob('/export/openmaptiles/*.log') {|path|
	stat if $count
	($min, $max, $count) = [0, 0, 0]
	area = File.basename(path, '.log')
	print "#{area} "
	File.foreach(path, :encoding => 'utf-8') {|l|
		download(l) if l.include?('bytes downloaded')
		took(l) if l.include?('took: ')
		speed(l) if l.include?('/s | ')
		hundred(l) if l.include?('100.0000%')
	}
	mb = "/export/openmaptiles/#{area}.mbtiles"
	if File.exist?(mb)
	  print Sequel.sqlite(mb)[:tiles].count.to_s + " tiles\n"
  end
}
