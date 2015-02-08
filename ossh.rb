#!/usr/bin/env ruby

require "./dijkstra_spf.rb"

#sshpass -p miyakz ssh -l miyakz -o StrictHostKeyChecking=no 192.168.122.13 "sshpass -p debug00 ssh -l root -o StrictHostKeyChecking=no 192.168.122.40 hostname"

class Server
  attr_accessor :host, :ip, :login, :passwd
  def initialize(host:, ip:, login:, passwd:)
    @host = host
    @ip = ip
    @login = login
    @passwd = passwd
  end 
end

class Connection
  attr_accessor :from, :to
  def initialize(from: , to:)
    @from = from
    @to = to
  end
end

class ServerConnections
  attr_reader :path
  include InfinityCost

  def initialize
    @path = Path.new
  end

  def connect(from: , to: , cost: 1)
    n0 = @path.get_node(from)
    n1 = @path.get_node(to)
    n0.add_route(n1, cost)
    n1.add_route(n0, cost)
    @path.nodes << n0 << n1
  end

  def disconnect(from: , to:)
    raise "not implemented yet"
  end

  def connections(&block)
    yield self
  end
end

class OnionSsh
  attr_accessor :path_of_servers

  # _path_of_servers_ :: (Array) array of Server that Path generated
  def initialize(path_of_servers)
    @path_of_servers = path_of_servers
  end

  #TODO: use naitive ruby lib
  def ssh(command)
    sshpass_command = _ssh(@path_of_servers.dup, "", command)
    #replace first \"
    sshpass_command.sub!(/\"/,"")
    #added remains \"
    sshpass_command += "\"" * (@path_of_servers.size - 1)
  end

  #TODO: use naitive ruby lib
  def scp(file)
  end

protected

  # _path_of_servers_ :: (Array) array of Server that Path generated
  # _sshpass_command_ :: (string) sshpass_command that generated
  # _user_exec_command :: (string)
  def _ssh(path_of_servers, sshpass_command, user_exec_command)
    if path_of_servers.size == 0
      return "#{sshpass_command} #{user_exec_command}"
    end

    server = path_of_servers.shift

    sshpass_command += " \"sshpass -p #{server.passwd}"\
                       " ssh -l #{server.login}" \
                       " -o StrictHostKeyChecking=no" \
                       " #{server.ip}"

    _ssh(path_of_servers, sshpass_command, user_exec_command)
  end
end

s1 = Server.new(host: "juno01", ip: "192.168.122.13", login: "miyakz", passwd: "miyakz")
s2 = Server.new(host: "cent_icehouse01", ip: "192.168.122.40", login: "root", passwd: "debug00")
s3 = Server.new(host: "icehouse01", ip: "192.168.122.84", login: "miyakz", passwd: "miyakz")

sc = ServerConnections.new

sc.connections do |sc|
  sc.connect from: s1, to: s2
  sc.connect from: s2, to: s3
end

pt = sc.path.get(s1, s3)
#Path.dump(pt)

ossh = OnionSsh.new(pt)
puts ssh = ossh.ssh("hostname")
puts `#{ssh}`
