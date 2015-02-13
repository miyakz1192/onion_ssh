require "./server_connections"

$sc = ServerConnections.new
$servers = []
$server_groups = {}

def find_server_by_name(name)
  $servers.detect{|sv| sv.host == name}
end

def find_server_group_by_name(name)
  k = $server_groups.keys.detect{|group_name| group_name == name}
  $server_groups[k]
end

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
  return unless block.call.is_a?(Array)

  block.call.each do |sv_name|
    sv = find_server_by_name(sv_name)
    raise "ERROR: no such server name=#{sv_name}" unless sv
    sv.user = login_user_name
    sv.passwd = passwd
  end
end


def server_group(group_name, &block)
  return unless block.call.is_a?(Array)

  block.call.each do |sv_name|
    sv = find_server_by_name(sv_name)
    raise "ERROR: no such server name=#{sv_name}" unless sv
    if $server_groups[group_name] == nil
      $server_groups[group_name] = []
    end
    $server_groups[group_name] << sv
  end
end

def server_connections(&block)
  return unless block.call.is_a?(Array)

  block.call.each do |sv_pair|
    svg0 = find_server_group_by_name(sv_pair[0])
    svg1 = find_server_group_by_name(sv_pair[1])
    sv0 = find_server_by_name(sv_pair[0])
    sv1 = find_server_by_name(sv_pair[1])

    if sv0 && sv1
      servers_left = [sv0]
      servers_right = [sv1]
    elsif svg0 && svg1
      servers_left = svg0
      servers_right = svg1
    else
      servers_left = svg0 || svg1
      servers_right = [sv0 || sv1]
    end

    servers_left.product(servers_right).each do |sv_pair|
      $sc.connect(from: sv_pair[0], to: sv_pair[1])
    end
  end
end

=begin
begin
  eval(open("test_ossh_config_sample.txt").read)
rescue => e
  puts e.message
  puts e.backtrace()
end

puts "================servers===================="
puts $servers.map{|sv| "#{sv.host},#{sv.ip},#{sv.user},#{sv.passwd}"}

puts "================server_group===================="
$server_groups.each_key do |key|
  puts "group=>#{key}"
  $server_groups[key].each do |sv|
    puts "  mem=>#{sv.host}"
  end
end
=end

