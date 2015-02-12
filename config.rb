require "./server_connections"

$sc = ServerConnections.new
$servers = []

def load_from(file_name)
  open(file_name) do |f|
    while line = f.gets
      next if line =~ /^[[:space:]]*#.*/ || line =~ /^[[:space:]]+/
      ip   = line.split[0].chomp
      host = line.split[1].chomp
      $servers << Server.new(host: host, ip: ip)
    end
  end
end

def account_group(login_user_name, passwd, &block)
  return unless block.is_a?(Array)

  block.each do |sv_name|
    sv = $servers.detect{|sv| sv.host == sv_name}
    next unless sv
    sv.user = login_user_name
    sv.passwd = passwd
  end
end


def server_group(group_name)
end

def server_connections(&block)
end


#eval(open("config_sample.txt").read)

load_from("/etc/hosts")
puts $servers.map{|sv| "#{sv.host},#{sv.ip},#{sv.user},#{sv.passwd}"}

