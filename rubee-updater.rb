#!/usr/bin/ruby

print "REE Source URL: "
source_url = gets.chomp
source_file = source_url.split('/').last
source_dir = source_file[0..-8]
system("rm #{source_file}") if File.exists?(source_file)
system("wget #{source_url}")
system("tar -zxvf #{source_file}")
system("#{source_dir}/installer")
system("/opt/#{source_dir}/bin/passenger-install-apache2-module")
system("ln -sf /opt/#{source_dir} /opt/rubee")

exclude_gems = %w{ zentest vimmate vim-ruby validatable stone sequel rest-client net-toc herokugarden fxruby facets eventmachine english cmdparse passenger rake fastthread rack mysql sqlite3-ruby postgres  }
freshen_gems = %w{ rmagick haml mocha }
include_gems = %w{ ramaze }
gem_list = `gem list`.split("\n").map do |x|
  [x.slice(/^\b\S*\b/).downcase, x.slice(/\(.*\)/)[1..-2].split(', ')]
end
gem_list.delete_if { |x| exclude_gems.include? x.first }
gem_list.delete_if { |x| freshen_gems.include? x.first }
freshen_gems.each { |x| gem_list << [x, ['>= 0']] }
include_gems.each { |x| gem_list << [x, ['>= 0']] }
gem_list.each do |x|
  x[1].each do |y|
    #puts "#{x[0]} --version '#{y}'"
    system("/opt/rubee/bin/gem install #{x[0]} --version '#{y}' --no-ri --no-rdoc")
  end
end

File.open('/etc/apache2/conf.d/passenger', 'w') do |f|
  f.puts 'LoadModule passenger_module /opt/rubee/lib/ruby/gems/1.8/gems/passenger-2.0.6/ext/apache2/mod_passenger.so'
  f.puts 'PassengerRoot /opt/rubee/lib/ruby/gems/1.8/gems/passenger-2.0.6'
  f.puts 'PassengerRuby /opt/rubee/bin/ruby'
  f.puts 'PassengerPoolIdleTime 1800'
end

system('/etc/init.d/apache2 restart')
