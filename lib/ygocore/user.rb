class User
  attr_reader :certified

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
    case @affiliation
    when :owner
      [220,20,60]
    when :admin
      [148, 43, 226]
    else
      @certified ? [0, 0, 0] : [128, 128, 128]
    end
  end

  def space
    if @certified
      Dialog.web "https://my-card.in/users/#{CGI.escape @id.to_s}"
    else
      Widget_Msgbox.new("查看资料", "用户#{@name}没有注册", :ok => "确定")
    end
  end

  def avatar(size = :small)
    id = (@id.respond_to?(:bare) ? @id.bare : @id).to_s
    cache = "graphics/avatars/mycard_#{id}_#{size}.png"
    result = Surface.load(cache) rescue Surface.load("graphics/avatars/loading_#{size}.png")
    scene = $scene
    if block_given?
      yield result
      Thread.new do
        require 'cgi'
        $log.info('读取头像') { "https://my-card.in/users/#{CGI.escape id.to_s}.png" }
        begin
          open("https://my-card.in/users/#{CGI.escape id.to_s}.png", 'rb') { |io| open(cache, 'wb') { |c| c.write io.read } }
        rescue Exception => exception
          $log.error('下载头像') { [exception.inspect, *exception.backtrace].join("\n").force_encoding("UTF-8") }
          cache = "graphics/avatars/error_#{size}.png"
        end
        (yield Surface.load(cache) if scene == $scene) rescue nil
      end
    else
      result
    end
  end
end
