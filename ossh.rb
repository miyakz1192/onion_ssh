#!/usr/bin/env ruby 

require "./ossh_lib"
require "./config"
require 'optparse'

if ARGV.size != 2
  puts "usage: target_server command"
  exit 1
end

target_server_name = ARGV[0]
command = ARGV[1]

read_config

localhost = find_server_by_name("localhost")
target_server = find_server_by_name(target_server_name)

if localhost == nil || target_server == nil
  puts "ERROR: localhost or #{target_server_name} are not in config"
  exit 2
end

pt = server_connections_object.path.get(localhost, target_server)
puts OnionSsh.new.ssh(pt, command)
