
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
end

