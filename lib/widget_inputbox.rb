class Widget_InputBox < Window

  attr_accessor :text, :proc
  require 'tk'
  @@font = TkFont.new("family" => 'WenQuanYi Micro Hei', 
                    "size" => 15) #这字号尼玛？！
  @@root=TkRoot.new {
    withdraw
    overrideredirect true
    attributes :topmost, true
  }
  @@entry = TkEntry.new(@@root){
    font @@font
    validate :focusout
    validatecommand{@@active.text.replace(get);@@root.withdraw(true);@@active.refresh;true}
    bind('Key-Return'){@@active.proc.call(get);delete(0, get.size);@@root.withdraw(true);true}
    pack
  }
  
  Thread.new{Tk.mainloop}
  def initialize(x,y,width,height,z=300, &block)
    super(x,y,width,height,z)
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 20)
    @proc = block
    @text = ""
  end
  def refresh
    @contents.fill_rect(0,0,@width,@height,0x66000000)
    @font.draw_blended_utf8(@contents, @text, 0, 0, 0xFF, 0xFF, 0xFF) unless @text.empty?
  end
  def mousemoved(x,y)
  end
  def clicked
    @@active = self
    @@root.geometry "#{@width}x#{@height}+#{@x+TkWinfo.pointerx(@@root)-Mouse.state[0]}+#{@y+TkWinfo.pointery(@@root)-Mouse.state[1]}"
    @@entry.text @text
    @@entry.width @width
    @@root.deiconify
    @@entry.focus :force
  end

end
