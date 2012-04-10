class Room
  attr_accessor :pvp
  attr_accessor :match
  attr_accessor :status
  alias pvp? pvp
  alias match? match
  def full?
    $game.is_a?(Ygocore) ? (@status == :start) : player2 #不规范修正iduel房间识别问题
  end
  def extra
    result = {}
    if pvp?
      result["[竞技场]"] = [255,0,0]
    end
    if match?
      result["[三回决斗]"] = [255,0,0]
    end
    result
  end
end
