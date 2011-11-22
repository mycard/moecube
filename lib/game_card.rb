#encoding: UTF-8
class Game_Card
  attr_accessor :card, :position #attack|defense|set,
  attr_accessor :atk, :def
  @@count = 0
  def initialize(card=nil)
    @@count += 1
    puts "创建活动卡片<#{card ? card.name : '??'}>，共计#{@@count}张"
    @card = card || Card.find(nil)
    reset
  end
  def reset
    @position = :set
    @atk = @card.atk
    @def = @card.def
  end
  def known?
    @card != Card::Unknown
  end
  def image_small
    if @position == :set
      Card.find(nil).image_small
    else
      @card.image_small
    end
  end
  def method_missing(method, *args)
    if method.to_s[0,9]== "original_"
      method = method.to_s[9, method.to_s.size-9]
    end
    @card.send(method, *args)
  end
end