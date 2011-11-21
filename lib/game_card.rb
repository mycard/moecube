#encoding: UTF-8
class Game_Card
  attr_accessor :card, :position #attack|defense|set,
  @@count = 0
  def initialize(card=nil)
    @@count += 1
    puts "创建活动卡片<#{card ? card.name : '??'}>，共计#{@@count}张"
    @card = card || Card.find(nil)
    @position = :set
  end
  def known?
    true
  end
  def image_small
    if @position == :set
      Card.find(nil).image_small
    else
      @card.image_small
    end
  end
  def method_missing(method, *args)
    @card.send(method, *args)
  end
end