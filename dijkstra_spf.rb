require "pp"
require "depq"
require "forwardable"
require "set"

module InfinityCost
  INFINITY_COST = 65536
end

module DebugLogger
  class Log
    def self.debug(msg)
      puts msg
    end
  end
end

class Node
  include InfinityCost
  extend Forwardable
  attr_accessor :resource, :cost, :routes 
  attr_accessor :prev
  def_delegator :@resource, :hash

  def initialize(resource)
    @resource = resource
    @cost = INFINITY_COST
    @routes = Set.new
  end
  
  #to is Node, and cost is route cost
  def addRoute(to, cost = 1)
    @routes << Route.new(self, to, cost)
  end

  def eql?(other)
    @resource.eql?(other.resource)
  end
end

class Route
  attr_accessor :from, :to, :cost#from Node, to Node, and it's route cost
  def initialize(from, to, cost = 1)
    @from = from
    @to = to
    @cost = cost
  end
end

#my extention
class Depq
  def poll
    node, cost = delete_min_priority
    return node
  end

  def update_node(node)
    delete(node)
    insert(node, node.cost)
  end

  def delete(node)
    each_locator do |loc|
      if loc.value == node
        delete_locator(loc)
        return
      end
    end
  end

  def node(node)
    each_locator do |loc|
      return loc.value if loc.value == node
    end
    return nil
  end
end

class Path

  include DebugLogger

  def initialize(nodes: Set.new)
    @nodes = nodes
    init_depq
  end

  #dijkstra algorithm
  def get(start, _end)
    @ans = []
    snode = node(start)
    return unless snode

    snode.cost = 1
    @q.update_node(snode)
    until @q.empty?
      n = @q.poll
#      Log.debug "selected => #{n.resource.sw.name}:#{n.resource.no}"
      n.routes.each do |r|
#        Log.debug "  route #{r.to.resource.sw.name}:#{r.to.resource.no},r.to.cost=#{r.to.cost}, r.cost + n.cost = #{r.cost + n.cost}"
        if r.to.cost > r.cost + n.cost
#          Log.debug "  update cost"
          r.to.cost = r.cost + n.cost
          @q.update_node(r.to)
#          Log.debug "  updated cost #{@q.node(r.to).resource.sw.name}:#{@q.node(r.to).resource.no} cost => #{@q.node(r.to).cost}"
          r.to.prev = n
        end
      end
    end
    ans = []
    n = node(_end)
    return [] unless n

    ans << n.resource
    while n.prev
      ans << n.prev.resource
      n = n.prev
    end
    return ans.reverse
  end

  def self.dump(pt)
    return unless pt
    Log.debug pt.inject(""){|res, p| res += "#{p.inspect}<->"}    
  end

###################################
protected
###################################

  def get_node(resource)
    n = node(resource)
    return n if n
    return Node.new(resource)
  end

  def node(resource)
    @nodes.find{|n| n.resource == resource}
  end

  def init_depq
    @q = Depq.new
    @nodes.each{|n| @q.insert(n, n.cost)}
  end
end
