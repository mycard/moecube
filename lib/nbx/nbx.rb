#encoding: UTF-8
class NBX < Game
  Version = "20090622"
  Port=2583
  RS = "\xA1\xE9".force_encoding "GBK"
  def initialize
    super
    require 'socket'
    require 'digest/md5'
    require 'open-uri'
    require_relative 'action'
    require_relative 'event'
    require_relative 'user'
    require_relative 'room'

    @conn_hall = UDPSocket.new
    @conn_hall.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
    @conn_hall.bind('0.0.0.0', Port)
    @recv_hall = Thread.new { recv *@conn_hall.recvfrom(1024) while @conn_hall }
    Thread.abort_on_exception = true
  end
  def send(user, head, *args)
    case user
    when User  #大厅里给特定用户的回复
      @conn_hall.send("#{head}|#{args.join(',')}", 0, user.host, Port)
    when nil #大厅里的广播
      @conn_hall.send("#{head}|#{args.join(',')}", 0, '<broadcast>', Port)
    when :room #房间里，发给对手和观战者
      @conn_room.write(head.encode("GBK") + RS)
    when :watchers #房间里，发给观战者
      
    end
    
  end

  def login(username)
    Game_Event.push Game_Event::Login.new(User.new('localhost', username))
  end
  def host
    @room = Room.new(@user.id, @user.name, @user)
    Game_Event.push Game_Event::Host.new(@room)
    send(nil, "NewRoom", @room.player1.name)
    @conn_room_server = TCPServer.new '0.0.0.0', Port  #为了照顾NBX强制IPv4
    @accept_room = Thread.new{Thread.start(@conn_room_server.accept) {|client| accept(client)} while @conn_room_server}
  end
  def action(action)
    if @room.player2
      action.from_player = false
      send(:room, action.escape)
      action.from_player = true
    end
  end
  def accept(client)
    if @conn_room #如果已经连接了，进入观战
      
    else #连接
      @conn_room = client
      @conn_room.set_encoding "GBK"
      send(:room, "[LinkOK]|#{Version}")
      send(:room, "▓SetName:#{@user.name}▓")
      send(:room, "[☆]开启 游戏王NetBattleX Version  2.7.0\r\n[10年3月1日禁卡表]\r\n▊▊▊E8CB04")
      @room.player2 = User.new(client.addr[2], "对手")
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
    Game_Event.push Game_Event.parse info
  end
  def refresh
    send(nil, 'NewUser', @user.name, 1)
  end
  def join(host, port=Port)
    Thread.new {
      @conn_room = TCPSocket.new(host, port)
      @conn_room.set_encoding "GBK"
      @room = Room.new(@user.id, @user.name, @user)
      Game_Event.push Game_Event::Join.new(@room)
      send(:room, "[VerInf]|#{Version}")
      send(:room, "▓SetName:#{@user.name}▓")
      send(:room, "[☆]开启 游戏王NetBattleX Version  2.7.0\r\n[10年3月1日禁卡表]\r\n▊▊▊E8CB04")
      @room.player2 = User.new(host, "对手")
      while info = @conn_room.gets(RS)
        recv_room(info)
      end
      @conn_room.close
    } #TODO: 跟accept合并
  end
  
  def recv(info, addrinfo)
    puts ">> #{info} -- #{addrinfo[2]}"
    Socket.ip_address_list.each do |localhost_addrinfo|
      if localhost_addrinfo.ip_address == addrinfo[3]
        addrinfo[2] = 'localhost'
        break
      end
    end
    Game_Event.push Game_Event.parse(info, addrinfo[2])
  end
end


