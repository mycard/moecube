#encoding: UTF-8
require_relative 'iduel'
class NBX < Iduel
  Version = "20090622"
  Port=2583
  RS = "\xA1\xE9".force_encoding "GBK"
  attr_accessor :user
  def initialize
    require 'socket'
    require 'digest/md5'
    require 'open-uri'
    #require_relative 'iduel_action'
    require_relative 'nbx_event'
    require_relative 'nbx_user'
    #require_relative 'iduel_room'

    @conn_hall = UDPSocket.new
    @conn_hall.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
    @conn_hall.bind('0.0.0.0', Port)
    @recv = Thread.new { recv *@conn_hall.recvfrom(1024) while @conn_hall }
    Thread.abort_on_exception = true
  end
  def send(user, head, *args)
    @conn_hall.send("#{head}|#{args.join(',')}", 0, user ? user.host : '<broadcast>', Port)
  end
  def login(username)
    send(nil, 'USERONLINE', username, 1)
    @user = User.new(username, 'localhost')
  end
  def connect(server, port=Port)
    #@conn = TCPSocket.open(server, port)
    #@conn.set_encoding "GBK"
    #@recv = Thread.new { recv @conn.gets(RS) while @conn  }
  end
  
  def recv(info, addrinfo)
    Socket.ip_address_list.each do |localhost_addrinfo|
      if localhost_addrinfo.ip_address == addrinfo[3]
        addrinfo[2] = 'localhost'
        break
      end
    end
    Event.push Event.parse(info, addrinfo[2])
  end
end


