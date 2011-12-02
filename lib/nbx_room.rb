class NBX::Room
  @@all = []
  attr_accessor :player1, :player2
  class << self
    alias old_new new
    def new(player1, player2=nil)
      room = @@all.find{|room| room.player1 == player1 }
      if room
        room
      else
        room = old_new(player1, player2)
        @@all << room
        room
      end
    end
  end
  def initialize(player1, player2=nil)
    @player1 = player1
    @player2 = player2
  end
  def id
    player1.host
  end
  def name
    player1.name
  end
  def color
    [0,0,0]
  end
  def private?
    false
  end
  alias full? player2
end