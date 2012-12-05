class User
  attr_accessor :level, :exp
  def self.parse(info)
    if info =~ /(.+)\((\d+)\)/
      new $2.to_i, $1
    else
      nil
    end
  end
  def initialize(id, name = "", level = nil, exp = nil)
    @id = id
    @name = name
    @level = level
    @exp = exp
  end
  def set(id, name = :keep, level = :keep, exp = :keep)
    @id = id unless id == :keep
    @name = name unless name == :keep
    @level = level unless level == :keep
    @exp = exp unless exp == :keep
  end
  def avatar(size = :small)
    cache = "graphics/avatars/#{@id}_#{size}.png"
    result = Surface.load(cache) rescue Surface.load("graphics/avatars/loading_#{size}.png")
    scene = $scene
    if block_given?
      yield result
      Thread.new do
        open("http://www.duelcn.com/uc_server/avatar.php?uid=#{id-100000}&size=#{size}", 'rb') {|io|open(cache, 'wb') {|c|c.write io.read}} rescue cache = "graphics/avatars/error_#{size}.png"
        (yield Surface.load(cache) if scene == $scene) rescue nil
      end
    else
      result
    end
  end
  def status
    room = room()
    result = case
    when room.nil?
      :lobby
    when room.player2
      :dueling
    else
      :waiting
    end
    result
  end
  def room
    $game.rooms.find{|room|room.include? self}
  end
  def space
    Dialog.web "http://www.duelcn.com/home.php?mod=space&uid=#{@id-100000}"
  end
  def color
    @friend ? [255,0,0] : [0,0,0]
  end
end
