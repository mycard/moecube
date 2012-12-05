require_relative 'cacheable'
class Room
  Color = [[0,0,0], [255,0,0], [0,128,0], [0,0,255], [255, 165, 0]]
  extend Cacheable
  attr_accessor :id, :name, :player1, :player2, :private, :color, :forbid, :_deleted
  attr_accessor :password
  def initialize(id, name="等待更新", player1=nil, player2=nil, private=false, color=[0,0,0], session = nil, forbid = nil)
    @id = id
    @name = name
    @player1 = player1
    @player2 = player2
    @private = private
    @color = color
    @session = session
    @forbid = forbid
  end
  def set(id=:keep, name=:keep, player1=:keep, player2=:keep, private=:keep, color=:keep, session = nil, forbid=:keep)
    @id = id unless id == :keep
    @name = name unless name == :keep
    @player1 = player1 unless player1 == :keep
    @player2 = player2 unless player2 == :keep
    @private = private unless private == :keep
    @color = color unless color == :keep
    @session = session unless session == :keep
    @forbid = forbid unless forbid == :keep
  end
  def include?(user)
    @player1 == user or @player2 == user
  end
  def extra
    {}
  end
  def status
    player2 ? :start : :wait
  end
  alias full? player2
  alias private? private
end