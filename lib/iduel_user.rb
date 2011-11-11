class Iduel::User
  @@all = []
  attr_accessor :id, :name, :level, :exp    
  class << self
    alias old_new new
    def new(id, name = "", level = nil, exp = nil)
      if id.is_a? String and id =~ /(.*)\((\d+)\)/
        id = $2.to_i
        name=$1
      else
        id = id.to_i
      end
      user = @@all.find{|user| user.id == id }
      if user
        user.name = name if name
        user.level = level if level
        user.exp = exp if exp
        user
      else
        user = old_new(id, name, level, exp)
        @@all << user
        user
      end
    end
  end
  def initialize(id, name = "", level = nil, exp = nil)
    @id = id
    @name = name
    @level = level
    @exp = exp
  end
  def avatar(size = :small)
    cache = "graphics/avatars/#{@id}_#{size}.png"
    result = Surface.load(cache) rescue Surface.load("graphics/avatars/loading_#{size}.gif")
    if block_given?
      Thread.new do
        open("http://www.duelcn.com/uc_server/avatar.php?uid=#{id-100000}&size=#{size}", 'rb') {|io|open(cache, 'wb') {|c|c.write io.read}} rescue cache = "graphics/avatars/noavatar_#{size}.gif"
        yield Surface.load cache
      end
      yield result
    else
      result
    end
  end
  def status
    room = $iduel.rooms.find{|room|room.player1 == @user or room.player2 == @user}
    result = case
    when room.nil?
      "等待中"
    when room.player2
      "房间#{room.id}决斗中"
    else
      "房间#{room.id}等待中"
    end
    result
  end
end