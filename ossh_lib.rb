require "./dijkstra_spf"
require "securerandom"
require "./server_connections"
require "open3"

class OnionSsh
  attr_accessor :path_of_servers

  #TODO: to be configurable
  TEMP_DIR="/tmp/onion_ssh"

  #TODO: use naitive ruby lib
  # _path_of_servers_ :: (Server of Array) path_of_servers
  # _command_ :: (String) command to exec
  # return :: (Array) first(String) stdout
  #                   second(String) stderr
  #                   third(Process::Status) result code
  def ssh(path_of_servers, command)
    _path_of_servers = path_of_servers.dup
    remove_first_localhost!(_path_of_servers)
    Open3.capture3(ssh_str(_path_of_servers, command))
  end

  #TODO: use naitive ruby lib
  def ssh_without_dquote_command(path_of_servers, command)
    _path_of_servers = path_of_servers.dup
    remove_first_localhost!(_path_of_servers)
    Open3.capture3(ssh_str_without_dquote_command(_path_of_servers, command))
  end

  #TODO: use naitive ruby lib
  def scp(src_file, path_of_servers, dst_file, option = "")
    _path_of_servers = path_of_servers.dup
    remove_first_localhost!(_path_of_servers)

    #generate session uuid and make temp dir string
    sid = SecureRandom.uuid
    temp_file = "#{temp_dir(sid)}#{File.basename(src_file)}"

    #first, local src file to edge server's temp dir
    #(/tmp/onion_ssh/<session uuid>/<files>)
    first = _path_of_servers.shift
    ssh([first], "mkdir -p #{temp_dir(sid)} >& /dev/null")
    `#{one_scp_str(src_file, first, temp_file)}`
    
    #second to last - 1 , scp temp dir to temp dir
    last = _path_of_servers.pop
    temp_path = [first]
    _second_to_last_minus_one = _path_of_servers
    _second_to_last_minus_one.each do |sv|
      temp_path << sv
      ssh(temp_path,"mkdir -p #{temp_dir(sid)} >& /dev/null")
    end

    temp_path = [first]
    _second_to_last_minus_one.each do |sv|
      ssh(temp_path, "#{one_scp_str(temp_file, sv, temp_dir(sid))}")
      temp_path << sv
    end

    #last minus one's path=(temp_path above) and last
    ssh(temp_path, "#{one_scp_str(temp_file, last, dst_file)}")
    #delete garbage
    clear_temp([first] + _second_to_last_minus_one, sid)
  end

  def clear_temp(path_of_servers, sid="all")
    _path_of_servers = path_of_servers.dup
    remove_first_localhost!(_path_of_servers)

    temp_path = []
    _path_of_servers.each do |sv|
      temp_path << sv
      if sid == "all"
        ssh(temp_path, "rm -rf #{TEMP_DIR} >& /dev/null")
      else
        ssh(temp_path, "rm -r #{temp_dir(sid)} >& /dev/null")
      end
    end
  end

#################################
protected
#################################

  def temp_dir(session_id)
    "/tmp/onion_ssh/#{session_id}/"
  end

  def remove_first_localhost!(path_of_servers)
    if path_of_servers.first.host == "localhost"
      path_of_servers.shift
    end
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

