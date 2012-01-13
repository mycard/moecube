#encoding: UTF-8
class Game_Card
  attr_accessor :card, :position #attack|defense|set,
  attr_accessor :atk, :def
  @@count = 0
  def initialize(card=nil)
    @@count += 1
    $log.info  "创建活动卡片<#{card ? card.name : '??'}>，共计#{@@count}张"
    @card = card || Card.find(nil)
    reset
  end
  def atk
    @card.atk.to_i #把"?"转为0
  end
  def def
    @card.atk.to_i #把"?"转为0
  end
  def reset(reset_position = true)
    @position = :set if reset_position
    @atk = @card.atk
    @def = @card.def
  end
  def card=(card)
    @card = card  
    reset(false)
  end
  def known?
    @card != Card::Unknown
  end
  def image_small
    if @position == :set and !$game.player_field.hand.include?(self)
      Card.find(nil).image_small
    else
      @card.image_small
    end
  end
  def image_horizontal
    if @position == :set and !$game.player_field.hand.include?(self)
      Card.find(nil).image_horizontal
    else
      @card.image_horizontal
    end
  end
  def method_missing(method, *args)
    if method.to_s[0,9]== "original_"
      method = method.to_s[9, method.to_s.size-9]
    end
    @card.send(method, *args)
  end
end