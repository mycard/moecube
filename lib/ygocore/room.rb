#encoding: UTF-8
class Room
  attr_accessor :pvp
  attr_accessor :match
  alias pvp? pvp
  alias match? match
  def full?
    color == [255,0,0]  #方法不规范 凑合用
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
