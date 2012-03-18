#encoding: UTF-8
load File.expand_path('window_login.rb', File.dirname(__FILE__))
require 'open-uri'
class Iduel < Game
  Version = "20110131"
  Server = "iduel.ocgsoft.cn"
  Register_Url = 'http://www.duelcn.com/member.php?mod=join_id'
  Port = 38522
  RS = "￠"
  attr_accessor :session
  attr_accessor :key
  def initialize
    super
    require 'digest/md5'
    load File.expand_path('action.rb', File.dirname(__FILE__))
    load File.expand_path('event.rb', File.dirname(__FILE__))
    load File.expand_path('user.rb', File.dirname(__FILE__))
    load File.expand_path('replay.rb', File.dirname(__FILE__))
  end

  def rename
    ##8|241019,测试改昵称,5b58559aaf8869282fe3cb9585ffa909￠
    #$N|iDuel系统,您的改名请求已经提交，重新登录后即可看到效果。￠
  end
  def login(username, password)
    connect
    md5 = Digest::MD5.hexdigest(password)
    send(0, username, md5, checknum("LOGINMSG", username, md5), Version)
  end
  def refresh
    send(1, @key, checknum("UPINFOMSG", @session))
  end
  def host(name, password="", lv=0, color = 0)
    
  end
  def host(room_name, room_config)
    password = ""
    color = 0
    lv = 0
    send(6, @key, room_name, password, checknum("JOINROOMMSG", @session + room_name + password + "0"), 0, color, lv, 0, 0, 0) #TODO:v.ak, v.al
  end
  def join(room, password="")
    send(6, @key, room.id, password, checknum("JOINROOMMSG", @session + room.id.to_s + password + "1"),1)
  end
  def watch(room, password="")
    send(5, @key, room.id, password, checknum("WATCHROOMMSG", "#{@session}#{room.id}#{password}"))
  end
  def leave
    return unless @room
    if @room.include? @user
      send(10, @key, room.id, checknum("QROOM", @session + room.id.to_s))
    else
      send(9, @key, checknum("QUITWATCHROOM", @session))
    end
  end
  def action(action)
    send(2, "#{checknum("RMSG", @session)}@#{@key}", "#{action.escape}▊▊▊mycard") #消息校验字串，为了防止由于mycard开源造成外挂泛滥扰乱正常iduel秩序，这里不模仿iduel计算校验字串，直接发送mycard供iduel识别
  end
  def exit
    @recv.exit if @recv
    if @conn
      leave
      send(11, @key, checknum("ULO", "#{@session}")) 
      @conn.close
      @conn = nil
    end
  end
  def recv(info)
    if info.nil?
      @conn.close
      @conn = nil
      $log.error 'socket已中断'
      Game_Event.push Game_Event::Error.parse(0)
    else
      info.chomp!(RS)
      info.delete!("\r")
      $log.info  ">> #{info}"
      Game_Event.push Game_Event.parse info
    end
  end

  #def qroom(room)
  #  send(10, @key, room.id, checknum("QROOM", @session + room.id.to_s))
  #end
  def chat(chatmessage)
    msg = chatmessage.message.gsub(",", "@@@@")
    case chatmessage.channel
    when :lobby
      send(4, @key, msg, checknum("CHATP", @session))
    when User #私聊
      send(3, @key, "#{chatmessage.channel.name}(#{chatmessage.channel.id})", msg, checknum("CHATX", @session + "X" + "#{chatmessage.channel.name}(#{chatmessage.channel.id})"))
    when Room #房间消息：向双方分别私聊
      channel = chatmessage.channel
      chatmessage.channel = channel.player1
      chat chatmessage
      if channel.player2
        chatmessage.channel = channel.player2
        chat chatmessage
      end
      chatmessage.channel = channel
    end
    
    #4|241019,test,2368c6b89b3e2eedb92e1b624a2a157c
  end
  def get_friends
    $config['iDuel']['friends'] ||= []
    $config['iDuel']['friends'].each {|id|User.new(id).friend = true}
    Thread.new do
      begin
        open("http://www.duelcn.com/home.php?mod=space&uid=#{@user.id-100000}&do=friend&view=me&from=space") do |file|
          $config['iDuel']['friends'].each {|id|User.new(id).friend = false}
          $config['iDuel']['friends'].clear
          file.set_encoding "GBK", "UTF-8"
          file.read.scan(/<a href="home.php\?mod=space&amp;uid=(\d+)" title=".*" target="_blank">.*<\/a>/) do |uid, others|
            id = uid.to_i + 100000
            User.new(id).friend = true
            $config['iDuel']['friends'] << id
          end
          save_config
        end
      rescue Exception => exception
        $log.error('读取好友信息') {[exception.inspect, *exception.backtrace].collect{|str|str.encode("UTF-8")}.join("\n")}
      end
    end
  end
  private
  def connect
    require 'socket'
    begin
      @conn = TCPSocket.new(Server, Port) #TODO: 阻塞优化，注意login。下面注释掉的两句实现connect无阻塞，但是login依然会阻塞所以只优化这里没有意义
      #@conn = Socket.new(:INET, :STREAM)
      @conn.set_encoding "GBK", "UTF-8", :invalid => :replace, :undef => :replace
      Thread.abort_on_exception=true
      @recv = Thread.new do
        begin
          #@conn.connect Socket.pack_sockaddr_in(Port, Server)
          recv @conn.gets(RS) while @conn
        rescue => exception
          $log.error('iduel-connect-1') {[exception.inspect, *exception.backtrace].collect{|str|str.encode("UTF-8")}.join("\n")}
          Game_Event.push Game_Event::Error.new(exception.class.to_s, exception.message)
        ensure
          self.exit
        end
      end
    rescue => exception
      $log.error('iduel-connect-2') {[exception.inspect, *exception.backtrace].collect{|str|str.encode("UTF-8")}.join("\n")}
      Game_Event.push Game_Event::Error.new("网络错误", "连接服务器失败")
    end
  end
  def checknum(head, *args)
    Digest::MD5.hexdigest("[#{head}]_#{args.join('_')}_SCNERO".gsub("\n", "\r\n").encode("GBK"))
  end
  def send(head, *args)
    return unless @conn
    info = "##{head.to_s(16).upcase}|#{args.join(',')}" + RS
    $log.info  "<< #{info}"
    info.gsub!("\n", "\r\n")
    (@conn.write info) rescue Game_Event.push Game_Event::Error.new($!.class.to_s, $!.message)
  end
  def self.get_announcements
    #公告
    $config['iDuel']['announcements'] ||= [Announcement.new("正在读取公告...", nil, nil)]
    Thread.new do
      begin
        open('http://www.duelcn.com/topic-Announce.html') do |file|
          file.set_encoding "GBK"
          announcements = []
          file.read.scan(/<li><em>(.*?)<\/em><a href="(.*?)" title="(.*?)" target="_blank">.*?<\/a><\/li>/).each do |time, url, title|
            if time =~ /(\d+)-(\d+)-(\d+)/
              time = Time.new($1, $2, $3)
            else
              time = nil
            end
            announcements << Announcement.new(title.encode("UTF-8"), "http://www.duelcn.com/#{url}", time)
          end
          $config['iDuel']['announcements'].replace announcements
          save_config
        end
      rescue Exception => exception
        $log.error('公告') {[exception.inspect, *exception.backtrace].collect{|str|str.encode("UTF-8")}.join("\n")}
      end
    end
  end
  get_announcements
end
