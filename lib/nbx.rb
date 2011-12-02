#encoding: UTF-8
require_relative 'iduel'
class NBX < Iduel
  Version = "20090622"
  Port=2583
  RS = "\xA1\xE9".force_encoding "GBK"
  attr_accessor :user, :room
  def initialize
    require 'socket'
    require 'digest/md5'
    require 'open-uri'
    require_relative 'nbx_action'
    require_relative 'nbx_event'
    require_relative 'nbx_user'
    require_relative 'nbx_room'

    @conn_hall = UDPSocket.new
    @conn_hall.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
    @conn_hall.bind('0.0.0.0', Port)
    @recv_hall = Thread.new { recv *@conn_hall.recvfrom(1024) while @conn_hall }
    Thread.abort_on_exception = true
  end
  def send(user, head, *args)
    case user
    when NBX::User  #大厅里给特定用户的回复
      @conn_hall.send("#{head}|#{args.join(',')}", 0, user.host, Port)
    when nil #大厅里的广播
      @conn_hall.send("#{head}|#{args.join(',')}", 0, '<broadcast>', Port)
    when :room #房间里，发给对手和观战者
      @conn_room.write(head.encode("GBK") + RS)
    when :watchers #房间里，发给观战者
      
    end
    
  end

  def login(username)
    @user = User.new(username, 'localhost')
    send(nil, 'USERONLINE', username, 1)
  end
  def host
    @room = NBX::Room.new(@user)
    #p @room
    #if room.player2
    #  @conn_hall.send(nil, "SingleRoomInfo", room.player1.name,room.player2.name, room.player2.host)
    #else
    send(nil, "SingleRoomInfo", @room.player1.name)
    #end
    @conn_room_server = TCPServer.new '0.0.0.0', Port  #为了照顾NBX强制IPv4
    
    @accept_room = Thread.new{Thread.start(@conn_room_server.accept) {|client| accept(client)} while @conn_room_server}
  end
  def accept(client)
    if @conn_room #如果已经连接了，进入观战
      
    else #连接
      @conn_room = client
      @conn_room.set_encoding "GBK"
      send(:room, "[LinkOK]|#{Version}")
      send(:room, "▓SetName:#{@user.name}▓")
      send(:room, "[☆]开启 游戏王NetBattleX Version  2.7.0\r\n[10年3月1日禁卡表]\r\n▊▊▊E8CB04")
      @room.player2 = User.new("对手", client.addr[2])
      while info = @conn_room.gets(RS)
        recv_room(info)
      end
      @conn_room.close
      #send(:room, "▓SetName:zh▓") #原版协议里还要重复声明一次名字，不过似乎没什么用处，就给省略了
    end
  end
  def recv_room(info)
    info.chomp!(RS)    
    info.encode! "UTF-8", :invalid => :replace, :undef => :replace
    puts ">> #{info}"
    Event.push Event.parse info
  end
  def refresh
    send(nil, 'USERONLINE', @user.name, 1)
  end
  def connect(server, port=Port)
    #@conn = TCPSocket.open(server, port)
    #@conn.set_encoding "GBK"
    #@recv_hall = Thread.new { recv @conn.gets(RS) while @conn  }
  end
  
  def recv(info, addrinfo)
    puts ">> #{info} -- #{addrinfo[2]}"
    Socket.ip_address_list.each do |localhost_addrinfo|
      if localhost_addrinfo.ip_address == addrinfo[3]
        addrinfo[2] = 'localhost'
        break
      end
    end
    Event.push Event.parse(info, addrinfo[2])
  end
end


