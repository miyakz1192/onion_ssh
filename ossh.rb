#!/usr/bin/env ruby

require "./dijkstra_spf"
require "securerandom"

#sshpass -p miyakz ssh -l miyakz -o StrictHostKeyChecking=no 192.168.122.13 "sshpass -p debug00 ssh -l root -o StrictHostKeyChecking=no 192.168.122.40 hostname"

class Server
  attr_accessor :host, :ip, :user, :passwd
  def initialize(host:, ip:, user:, passwd:)
    @host = host
    @ip = ip
    @user = user
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

  #TODO: to be configurable
  TEMP_DIR="/tmp/onion_ssh"

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
  def scp(src_file, dst_file, option = "")
    _path_of_servers = @path_of_servers.dup

    #generate session uuid and make temp dir string
    temp_dir = "/tmp/onion_ssh/#{SecureRandom.uuid}/"
    temp_file = "#{temp_dir}#{dst_file}"

    #first, local src file to edge server's temp dir
    #(/tmp/onion_ssh/<session uuid>/<files>)
    first = _path_of_servers.shift
    `#{ssh_str(first, "mkdir -p #{temp_dir} >& /dev/null")}`
    `#{scp_str(src_file, first, temp_file)}`
    
    #second to last - 1 , scp temp dir to temp dir
    last = _path_of_servers.pop
    last_minus_one = _path_of_servers.pop
    _scp_second_to_last_minus_one(_path_of_servers)
    
    #last - 1 to last , scp temp dir to dest dir
    `#{ssh_str(last_minus_one, "mkdir -p #{temp_dir} >& /dev/null")}`
    `#{scp_str(src_file, first_sv, temp_file)}`
  end

#################################
protected
#################################

  # _path_of_servers_ :: (Array) array of Server that Path generated
  # _sshpass_command_ :: (string) sshpass_command that generated
  # _user_exec_command :: (string)
  def _ssh(path_of_servers, sshpass_command, user_exec_command)
    if path_of_servers.size == 0
      return "#{sshpass_command} #{user_exec_command}"
    end

    server = path_of_servers.shift
    #shell command needs double quote's escape
    sshpass_command += "\"#{ssh_str(server)}"
    _ssh(path_of_servers, sshpass_command, user_exec_command)
  end

  def ssh_str(server, command = "")
    " sshpass -p #{server.passwd}"\
    " ssh -l #{server.user}" \
    " -o StrictHostKeyChecking=no" \
    " #{server.ip} #{command}"
  end

  def scp_str(src_file, server, dst_file)
    " sshpass -p #{server.passwd}"\
    " scp" \
    " -o StrictHostKeyChecking=no" \
    " #{src_file}"
    " #{server.user}@#{server.ip}"
  end
end

s1 = Server.new(host: "juno01", ip: "192.168.122.13", user: "miyakz", passwd: "miyakz")
s2 = Server.new(host: "cent_icehouse01", ip: "192.168.122.40", user: "root", passwd: "debug00")
s3 = Server.new(host: "icehouse01", ip: "192.168.122.84", user: "miyakz", passwd: "miyakz")

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
