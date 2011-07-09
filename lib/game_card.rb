class Game_Card
  def initialize(card)
    @card = card
  end
  def method_missing(method, *args)
    @card.send(method, *args)
  end
end