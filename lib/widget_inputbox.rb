class Widget_InputBox < Window
  attr_reader :value, :proc
  attr_accessor :type
  
  require 'tk'
  Root=TkRoot.new{
    withdraw
    overrideredirect true
    attributes :topmost, true
  }
  Entry = TkEntry.new(Root){
    font TkFont.new "family" => 'WenQuanYi Micro Hei', "size" => 15
    validate :focusout
    validatecommand {Widget_InputBox.determine}
    bind('Key-Return'){self.value="" if @@active.proc.call(get.encode("UTF-8")) if @@active.proc;true} #两个if的解释：当存在proc时，call那个proc，如果执行结果为真就清空value
    pack
  }
  Thread.new{Tk.mainloop}
  
  def initialize(x,y,width,height,z=300, &proc)
    super(x,y,width,height,z)
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 20)
    @proc = proc
    @value = ""
    @type = :text
  end
  def value=(value)
    return if @value == value
    @value = value
    refresh
  end
  def refresh
    clear
    @font.draw_blended_utf8(@contents, @type == :password ? '*' * @value.size : @value, 2, 0, 0x00, 0x00, 0x00) unless @value.empty?
  end
  def clicked
    Entry.value = @value
    Entry.show @type == :password ? '*' : nil
    Entry.focus :force
    Entry.width @width
    Root.geometry "#{@width}x#{@height}+#{@x+TkWinfo.pointerx(Root)-Mouse.state[0]}+#{@y+TkWinfo.pointery(Root)-Mouse.state[1]}" #根据鼠标位置来确定游戏窗口的相对位置，点击的瞬间鼠标移动了的话会有误差
    Root.deiconify
    @@active = self #TODO:存在线程安全问题
  end
  def clear(x=0, y=0, width=@width, height=@height)
    @contents.fill_rect(x,y,width,height,0x110000FF)
    @contents.fill_rect(x+2,y+2,width-4,height-4,0xFFFFFFFF)
  end
  def update
    #puts "UPDATE:" + self.to_s
  end
  def self.determine
    @@active.value=Entry.get.encode("UTF-8");Root.withdraw(true);@@active.refresh;true
  end
end
