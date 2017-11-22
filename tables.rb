require 'sequel'

DB = Sequel::connect(
  'postgres://openmaptiles:openmaptiles@postgres/openmaptiles')

DB.tables.sort.each{|t|
  #next unless t.to_s.start_with?('osm')
  print "#{t.to_s}\t#{DB[t].count}\n"
}
