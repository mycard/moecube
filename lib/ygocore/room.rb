class Room
  attr_accessor :pvp
  attr_accessor :match
  attr_accessor :tag
  attr_accessor :ot
  attr_accessor :lp
  attr_accessor :status
  attr_accessor :server
  alias pvp? pvp
  alias match? match
  alias tag? tag
  def lp
    @lp ||= 8000
  end
  def ot
    @ot ||= 0
  end
  def full?
    $game.is_a?(Ygocore) ? (@status == :start) : player2 #不规范修正iduel房间识别问题
  end
  def extra
    result = {}
    if pvp?
      result["[竞技场]"] = [255,0,0]
    end
    if tag?
      result["[TAG双打]"] = [128,0,255]
    elsif match?
      result["[三回决斗]"] = [0xff,0x72,0]
    end
    if ot == 1
      result["[TCG]"] = [255,0,0]
    elsif ot == 2
      result["[O/T混]"] = [255,0,0]
    end
    if lp != 8000
      result["[LP: #{lp}]"] = [255,0,0]
    end
    result
  end

  def host_server
    servers = $game.servers
    servers.select!{|server|server.auth} if @pvp
    s = servers & $game.filter[:servers]
    servers = s if !s.empty?

    server = servers.min_by{|server|$game.rooms.select{|room|room.server == server}.size}

    server ||= Server.new(nil, "", $game.server, $game.port, true)
    self.server = server
    server
  end
end
