#!/usr/bin/env ruby 

require "./ossh_lib"
require "./config"
require 'optparse'

if ARGV.size != 3
  puts "usage: src_file target_server dst_file "
  exit 1
end

src_file = ARGV[0]
target_server_name = ARGV[1]
dst_file = ARGV[2]

read_config

localhost = find_server_by_name("localhost")
target_server = find_server_by_name(target_server_name)

if localhost == nil || target_server == nil
  puts "ERROR: localhost or #{target_server_name} are not in config"
  exit 2
end

pt = server_connections_object.path.get(localhost, target_server)
OnionSsh.new.scp(src_file, pt, dst_file)
