#输入法by夏娜


module RM_IME
  if Windows
    require 'dl'
    require 'dl/import'
    extend DL::Importer
    Dir.chdir('ruby/bin') { dlload 'RMIME.dll' }
    extern 'void _init(long, int, int)'
    extern 'void _update(int, int)'
    extern 'void _dispose()'
    extern 'void _get_text(char*)'
    extern 'void _back(char*)'

    module RM_INPUT
      extend DL::Importer
      dlload 'user32.dll'
      extern 'int GetAsyncKeyState(int)'
      extern 'long FindWindow(char*, char*)'
      ENTER = 0x0D
      ESC = 0x1B
      TAB = 0x09
      UP = 0x26
      DOWN = 0x28
      LEFT = 0x25
      RIGHT = 0x27
      Key_Hash = {}
      Key_Repeat = {}

      module_function
      #----------------------------------------------------------------------
      # ● 按下判断
      #----------------------------------------------------------------------
      def press?(rkey)
        return GetAsyncKeyState(rkey) != 0
      end

      #----------------------------------------------------------------------
      # ● 重复按下判断
      #----------------------------------------------------------------------
      def repeat?(rkey)
        result = GetAsyncKeyState(rkey)
        if result != 0
          if Key_Repeat[rkey].nil?
            Key_Repeat[rkey] = 0
            return true
          end
          Key_Repeat[rkey] += 1
        else
          Key_Repeat[rkey] = nil
          Key_Hash[rkey] = 0
        end
        if !Key_Repeat[rkey].nil? and Key_Repeat[rkey] > 4
          Key_Repeat[rkey] = 0
          return true
        else
          return false
        end
      end

      #----------------------------------------------------------------------
      # ● 击键判断
      #----------------------------------------------------------------------
      def trigger?(rkey)
        result = GetAsyncKeyState(rkey)
        if Key_Hash[rkey] == 1 and result != 0
          return false
        end
        if result != 0
          Key_Hash[rkey] = 1
          return true
        else
          Key_Hash[rkey] = 0
          return false
        end
      end
    end
    HWND = RM_INPUT.FindWindow('SDL_app', WM.caption[0])
  end
  module_function

  def init
    return unless Windows
    return if @active
    $log.info('输入法') { '开启' }
    _init(HWND, 0, 0)
    @x = 0
    @y = 0
    @active = true
  end

  def set(x, y)
    return unless Windows
    @x = x
    @y = y
  end

  def text
    return "" unless Windows
    buf = 0.chr * 1024
    _get_text(buf)
    buf.force_encoding("UTF-8")
    buf.delete!("\0")
  end

  def update
    return unless Windows
    _update(@x, @y)
    buf = [0, 0].pack("LL")
    _back(buf)
    buf = buf.unpack("LL")
    @backspace = buf[0] == 1
    @delete = buf[1] == 1
  end

  def dispose
    return unless Windows
    return if !@active
    $log.info('输入法') { '关闭' }
    _dispose
    @active = false
  end

  def active?
    @active
  end

  def backspace?
    @backspace
  end

  def delete?
    @delete
  end

  def left?
    return unless Windows
    RM_INPUT.repeat?(RM_INPUT::LEFT)
  end

  def right?
    return unless Windows
    RM_INPUT.repeat?(RM_INPUT::RIGHT)
  end

  def tab?
    return unless Windows
    RM_INPUT.trigger?(RM_INPUT::TAB)
  end

  def enter?
    return unless Windows
    RM_INPUT.trigger?(RM_INPUT::ENTER)
  end


  def esc?
    return unless Windows
    RM_INPUT.trigger?(RM_INPUT::ESC)
  end
end
class Widget_InputBox < Window
  attr_accessor :type
  attr_reader :value
  attr_reader :index
  @@active = nil
  @@cursor = nil
  @@focus = true

  def initialize(x, y, width, height, z=300, &proc)
    super(x, y, width, height, z)
    @font = TTF.open(Font, 20)
    @proc = proc
    @value = ""
    @type = :text
    @index = 0
    @count = 0
    @char_pos = [2]
  end

  def value=(value)
    return if @value == value
    @value = value
    @char_pos.replace [2]
    @value.each_char do |char|
      @char_pos << @char_pos.last + @font.text_size(@type == :password ? '*' : char)[0]
    end
    if @index > value.size
      self.index = value.size
    end
    refresh
  end

  def index=(index)
    if index > @value.size
      index = @value.size
    elsif index < 0
      index = 0
    end
    return if @index == index
    @index = index
    @count = 0
    @@cursor.visible = true
    @@cursor.x = @x + @char_pos[@index]
    RM_IME.set(@@cursor.x, @@cursor.y)
  end

  def refresh
    clear
    @font.draw_blended_utf8(@contents, @type == :password ? '*' * @value.size : @value, 2, 0, 0x00, 0x00, 0x00) unless @value.empty?
  end

  def clicked
    RM_IME.init
    @@active = self
    @@focus = true
    unless @@cursor and !@@cursor.destroyed?
      @@cursor = Window.new(0, 0, 2, @height-4, 301)
      @@cursor.contents.fill_rect(0, 0, @@cursor.width, @@cursor.height, 0xFF000000)
    end
    @@cursor.y = @y + 2
    mouse_x = Mouse.state[0] - @x
    @index = nil #强制重置
    if mouse_x < 0 or @value.empty?
      self.index = 0
    else
      @char_pos.each_with_index do |x, index|
        if x > mouse_x
          return self.index = index - 1
        end
      end

      self.index = @value.size
    end

  end

  def clear(x=0, y=0, width=@width, height=@height)
    @contents.fill_rect(x, y, width, height, 0x110000FF)
    @contents.fill_rect(x+2, y+2, width-4, height-4, 0xFFFFFFFF)
  end

  def update
    return unless self == @@active and @@focus
    if @count >= 40
      @count = 0
      @@cursor.visible = !@@cursor.visible
    else
      @count += 1
    end
    RM_IME.update
    new_value = self.value.dup
    new_index = self.index
    text = RM_IME.text
    if !text.empty?
      new_value.insert(@index, text)
      new_index += text.size
    end
    if RM_IME.backspace? and @index > 0
      new_value.slice!(@index-1, 1)
      new_index -= 1
    end
    if RM_IME.delete? and @index < @value.size
      new_value.slice!(@index, 1)
    end
    if RM_IME.left?
      new_index -= 1
    end
    if RM_IME.right?
      new_index += 1
    end
    self.value = new_value
    self.index = new_index
    if @proc
      if RM_IME.esc?
        self.value = '' if @proc.call :ESC
      end
      if RM_IME.tab?
        self.value = '' if @proc.call :TAB
      end
      if RM_IME.enter? and text.empty?
        self.value = '' if @proc.call :ENTER
      end
    end
  end

  def destroy
    if @@active == self
      Widget_InputBox.focus = false
    end
    super
  end

  def self.focus=(focus)
    @@focus = focus
    if !@@focus
      RM_IME.dispose
      @@cursor.destroy if @@cursor
    end
  end
end