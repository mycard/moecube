class User
  def initialize(id, name = "", certified = true)
    @id = id
    @name = name
    @certified = certified
  end
  def set(id, name = :keep, certified = :keep)
    @id = id unless id == :keep
    @name = name unless name == :keep
    @certified = certified unless certified == :keep
  end
  def color
    @certified ? [0,0,0] : [128,128,128]
  end
  def space
    if @certified
      system("start http://card.touhou.cc/users/#{CGI.escape @id.to_s}")
    else
      Widget_Msgbox.new("查看资料", "用户#{@name}没有注册", :ok => "确定")
    end
  end
  def avatar(size = :small)
    cache = "graphics/avatars/mycard_#{@id}_#{size}.png"
    result = Surface.load(cache) rescue Surface.load("graphics/avatars/loading_#{size}.gif")
    scene = $scene
    if block_given?
      yield result
      Thread.new do
        require 'cgi'
        open("http://card.touhou.cc/users/#{CGI.escape @id.to_s}.png", 'rb') {|io|open(cache, 'wb') {|c|c.write io.read}} rescue cache = "graphics/avatars/noavatar_#{size}.gif"
        (yield Surface.load(cache) if scene == $scene) rescue nil
      end
    else
      result
    end
  end
end
