require "./server_connections"

$sc = ServerConnections.new
$servers = []

def load_from(file_name)
  open(file_name) do |f|
    while line = f.gets
      next if line =~ /^[:space]*#*/
      puts line
    end
  end
end

def account_group(login_user_name, passwd, &block)
end


def server_group(group_name)
end

def server_connections(&block)
end


eval(open("config_sample.txt").read)

