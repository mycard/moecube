require_relative 'cacheable'
class User
  attr_accessor :id, :name, :friend, :affiliation
  alias friend? friend
  extend Cacheable
  def initialize(id, name="")
    @id = id
    @name = name
  end
  def set(id, name = :keep)
    @id = id 
    @name = name unless name == :keep
  end
  def avatar(size = :small)
    Surface.new(SWSURFACE, 1, 1, 32, 0,0,0,0)
  end
  def status
    room = room()
    case
    when room.nil?
      :lobby
    when room.player2
      :dueling
    else
      :waiting
    end
  end
  def room
    $game && $game.rooms.find{|room|room.player1 == self or room.player2 == self}
  end
  def viewinfo
    
  end
  def color
    [0,0,0]
  end
  def space
    
  end
end