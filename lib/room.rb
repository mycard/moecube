class Room
  extend Cacheable
  attr_accessor :id, :name, :player1, :player2, :private, :color, :forbid
  def set(id, name, player1, player2=nil, private=false, color=[0,0,0], forbid = nil)
    @id = id
    @name = name
    @player1 = player1
    @player2 = player2
    @private = private
    @color = color
    @forbid = forbid
  end
  alias full? player2
  alias private? private
end