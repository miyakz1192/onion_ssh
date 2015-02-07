#!/usr/bin/env ruby

#sshpass -p miyakz ssh -l miyakz -o StrictHostKeyChecking=no 192.168.122.13 "sshpass -p debug00 ssh -l root -o StrictHostKeyChecking=no 192.168.122.40 hostname"

class Route
  attr_accessor :from, :to
  def initialize(from: "undefined_from", to: "undefined_to")
    @from = from
    @to = to 
  end 
end

class Router
  attr_accessor :routes

  def initialize
    routes = []
  end

  def add(route)
    routes << route
  end

  def del(route)
    routes.delete(route)
  end

  def find_destination(from)
    routes.detect{|r| r.from = from}
  end
end

class Account
  attr_accessor :host, :login, :passwd
  def initialize(host:, login:, passwd:)
    @host = host
    @login = login
    @passwd = passwd
  end 
end

a = Account.new(host: "192.168.122.13", login: "miyakz", passwd: "miyakz")
r = Route.new(from: "a", to: "b")

router = Router.new
router.add(r)

puts a.host, a.login, a.passwd
puts r.from, r.to


