class Room
  attr_accessor :pvp
  attr_accessor :match
  attr_writer :status
  alias pvp? pvp
  alias match? match
  def full?
    @status == :start
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
