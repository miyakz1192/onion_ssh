#!/usr/bin/env ruby

require "./dijkstra_spf.rb"

#sshpass -p miyakz ssh -l miyakz -o StrictHostKeyChecking=no 192.168.122.13 "sshpass -p debug00 ssh -l root -o StrictHostKeyChecking=no 192.168.122.40 hostname"

class Server
  attr_accessor :host, :login, :passwd
  def initialize(host:, login:, passwd:)
    @host = host
    @login = login
    @passwd = passwd
  end 
end

class ServerConnections
  attr_reader :nodes, :servers

  def initialize
    nodes = Set.new
  end

  def server(name:, ip:, login:, passwd:)
    
  end
end

s1 = Server.new(host: "192.168.122.13", login: "miyakz", passwd: "miyakz")
s2 = Server.new(host: "192.168.122.40", login: "root", passwd: "debug00")
s3 = Server.new(host: "192.168.122.84", login: "miyakz", passwd: "miyakz")



