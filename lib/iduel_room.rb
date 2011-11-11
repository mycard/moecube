class Iduel::Room
  @@all = []
  attr_accessor :id, :name, :player1, :player2, :private, :color
  class << self
    alias old_new new
    def new(id, *args)
      id = id.to_i
      room = @@all.find{|room| room.id == id }
      if room
        room
      else
        room = old_new(id, *args)
        @@all << room
        room
      end
    end
  end
  def initialize(id, name, player1, player2, private, color, session = nil, forbid = nil)
    @id =id
    @name = name
    @player1 = player1
    @player2 = player2
    @private = private
    @color = color
    @forbid = forbid
    @session = session
  end
  alias full? player2
  alias private? private
end