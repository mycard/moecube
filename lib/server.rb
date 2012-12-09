require_relative 'cacheable'
class Server
  attr_accessor :id, :name, :ip, :port, :auth
  extend Cacheable
  def initialize(id, name="", ip="", port=0, auth=false)
    @id = id
    @name = name
    @ip = ip
    @port = port
    @auth = auth
  end
  def set(id, name=:keep, ip=:keep, port=:keep, auth=:keep)
    @id = id
    @name = name unless name == :keep
    @ip = ip unless ip == :keep
    @port = port unless port == :keep
    @auth = auth unless auth == :keep
  end
end