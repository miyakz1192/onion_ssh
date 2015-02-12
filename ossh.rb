require "./dijkstra_spf"
require "securerandom"
require "server_connections"

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

  #TODO: use naitive ruby lib
  def ssh(path_of_servers, command)
    `#{ssh_str(path_of_servers, command)}`
  end

  #TODO: use naitive ruby lib
  def ssh_without_dquote_command(path_of_servers, command)
    `#{ssh_str_without_dquote_command(path_of_servers, command)}`
  end

  def ssh_str(path_of_servers, command)
    return if path_of_servers.size == 0
    if path_of_servers.size == 1
      #wrap command with "
      ssh_str_without_dquote_command(path_of_servers, "\"#{command}\"")
    else
      #wrap command with \"
      ssh_str_without_dquote_command(path_of_servers, "\\\"#{command}\\\"")
    end 
  end

  def ssh_str_without_dquote_command(path_of_servers, command)
    sshpass_command = _ssh(path_of_servers.dup, "", command)
    #replace first \"
    sshpass_command.sub!(/\"/,"")
    #added remains \"
    sshpass_command += "\"" * (path_of_servers.size - 1)
  end


  #TODO: use naitive ruby lib
  def scp(src_file, path_of_servers, dst_file, option = "")
    _path_of_servers = path_of_servers.dup

    #generate session uuid and make temp dir string
    temp_dir = "/tmp/onion_ssh/#{SecureRandom.uuid}/"
    temp_file = "#{temp_dir}#{File.basename(src_file)}"

    #first, local src file to edge server's temp dir
    #(/tmp/onion_ssh/<session uuid>/<files>)
    first = _path_of_servers.shift
    ssh([first], "mkdir -p #{temp_dir} >& /dev/null")
    `#{one_scp_str(src_file, first, temp_file)}`
    
    #second to last - 1 , scp temp dir to temp dir
    last = _path_of_servers.pop
    temp_path = [first]
    _second_to_last_minus_one = _path_of_servers
    _second_to_last_minus_one.each do |sv|
      temp_path << sv
      ssh(temp_path,"mkdir -p #{temp_dir} >& /dev/null")
    end

    temp_path = [first]
    _second_to_last_minus_one.each do |sv|
      ssh(temp_path, "#{one_scp_str(temp_file, sv, temp_dir)}")
      temp_path << sv
    end

    #last minus one's path=(temp_path above) and last
    ssh(temp_path, "#{one_scp_str(temp_file, last, dst_file)}")
  end

#################################
protected
#################################

  # _path_of_servers_ :: (Array) array of Server that Path generated
  # _sshpass_command_ :: (string) sshpass_command that generated
  # _user_exec_command :: (string)
  # return :: (string) nested scp command by sshpass
  def _ssh(path_of_servers, sshpass_command, user_exec_command)
    if path_of_servers.size == 0
      return "#{sshpass_command} #{user_exec_command}"
    end

    server = path_of_servers.shift
    #shell command needs double quote's escape
    sshpass_command += "\"#{one_ssh_str(server)}"
    _ssh(path_of_servers, sshpass_command, user_exec_command)
  end

  def one_ssh_str(server, command = "")
    " sshpass -p #{server.passwd}"\
    " ssh -l #{server.user}" \
    " -o StrictHostKeyChecking=no" \
    " #{server.ip} #{command}"
  end

  def one_scp_str(src_file, server, dst_file)
    " sshpass -p #{server.passwd}"\
    " scp" \
    " -o StrictHostKeyChecking=no" \
    " #{src_file}"\
    " #{server.user}@#{server.ip}:#{dst_file}"
  end
end

