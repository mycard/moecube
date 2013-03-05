class Window_Host < Window
  attr_reader :index
  def initialize(x,y)
    @button = Surface.load("graphics/system/button.png")
    @items = {:ok => [46,240,@button.w/3,@button.h], :cancel => [156,240,@button.w/3, @button.h]}
    @buttons = {:ok => "确定", :cancel => "取消"}
    @background = Surface.load('graphics/lobby/host.png').display_format
    super((1024-@background.w)/2, 230, @background.w, @background.h)
    @font = TTF.open(Font, 16)
    @title_color = [0xFF, 0xFF, 0xFF]
    @color = [0x04, 0x47, 0x7c]
    @roomname_inputbox = Widget_InputBox.new(@x+96, @y+41, 165, WLH)
    @password_inputbox = Widget_InputBox.new(@x+96, @y+41+WLH, 165, WLH)
    @lp_inputbox = Widget_InputBox.new(@x+96, @y+41+WLH*6+4, 64, WLH)
    
    @pvp = Widget_Checkbox.new(self, 33+@x,@y+41+WLH*2,120,24,false,"竞技场") {|checked|(@ocg.checked = true; @tcg.checked = @tag.checked = false; @lp_inputbox.value = "8000") if checked}
    @pvp.background = @background.copy_rect(33,70,120,24)
    @match = Widget_Checkbox.new(self, 120+@x,@y+41+WLH*2,120,24,true,"三回决斗"){|checked|@tag.checked = false if checked}
    @match.background = @background.copy_rect(120,70,120,24)
    @tag = Widget_Checkbox.new(self, 33+@x,@y+41+WLH*4+4,120,24,false,"TAG双打"){|checked|@pvp.checked = @match.checked = false if checked}
    @tag.background = @background.copy_rect(120,70,120,24)
    @ocg = Widget_Checkbox.new(self, 33+@x,@y+41+WLH*5+4,120,24,true,"OCG"){|checked|@tcg.checked = true if !checked}
    @ocg.background = @background.copy_rect(120,70,120,24)
    @tcg = Widget_Checkbox.new(self, 120+@x,@y+41+WLH*5+4,120,24,false,"TCG"){|checked|@pvp.checked = false if checked; @ocg.checked = true if !checked}
    @tcg.background = @background.copy_rect(120,70,120,24)
    
    @roomname_inputbox.value = rand(1000).to_s
    @lp_inputbox.value = 8000.to_s
    @password_inputbox.refresh
    @pvp.refresh
    @match.refresh
    @tag.refresh
    @ocg.refresh
    @tcg.refresh
    refresh
  end
  def refresh
    clear
    @font.draw_blended_utf8(@contents, "建立房间", (@width-@font.text_size("建立房间")[0])/2, 2, *@title_color)
    @font.draw_blended_utf8(@contents, "房间名", 33,43, *@color)
    @font.draw_blended_utf8(@contents, "房间密码", 33,43+WLH, *@color)
    @contents.fill_rect(4,43+WLH*3,@contents.w-8, 2, 0xAA0A7AC5)
    @font.draw_blended_utf8(@contents, "自定义模式", 20,43+WLH*3+4, *@color)
    @font.draw_blended_utf8(@contents, "初始LP", 33,44+WLH*6+4, *@color)
    @items.each_key do |index|
      draw_item(index, self.index==index ? 1 : 0)
    end
  end
  def draw_item(index, status=0)
    Surface.blit(@button,@button.w/3*status,0,@button.w/3,@button.h,@contents,@items[index][0],@items[index][1])
    text_size = @font.text_size(@buttons[index])
    @font.draw_blended_utf8(@contents, @buttons[index], @items[index][0]+(@button.w/3-text_size[0])/2, @items[index][1]+(@button.h-text_size[1])/2, 0xFF, 0xFF, 0xFF)
  end
  def mousemoved(x,y)
    new_index = nil
    @items.each_key do |index|
      if (x - @x).between?(@items[index][0], @items[index][0]+@items[index][2]) and (y-@y).between?(@items[index][1], @items[index][1]+@items[index][3])
        new_index = index
        break
      end
    end
    self.index = new_index
  end
  def item_rect(index)
    @items[index]
  end
  def index=(index)
    return if index == @index
    
    if @index
      clear(*item_rect(@index))
      draw_item(@index, 0) 
    end
    if index.nil? or !@items.include? index
      @index = nil
    else
      @index = index
      draw_item(@index, 1)
    end
  end
  def clicked
    case self.index
    when :ok
      if @roomname_inputbox.value.empty?
        Widget_Msgbox.new("建立房间", "请输入房间名", ok: "确定" )
      elsif !name_check
        Widget_Msgbox.new("建立房间", "房间名/房间密码超过长度上限", ok: "确定")
      elsif @lp_inputbox.value.to_i >= 99999
        Widget_Msgbox.new("建立房间", "初始LP超过上限", ok: "确定")
      else
        Widget_Msgbox.new("建立房间", "正在建立房间")
        destroy
        $game.host(@roomname_inputbox.value, password: @password_inputbox.value, pvp: @pvp.checked?, match: @match.checked?, tag: @tag.checked?, ot: @tcg.checked? ? @ocg.checked? ? 2 : 1 : 0, lp: @lp_inputbox.value.to_i)
      end
    when :cancel
      destroy
    end
  end
  def destroy
    @roomname_inputbox.destroy
    @password_inputbox.destroy
    @lp_inputbox.destroy
    @pvp.destroy
    @match.destroy
    @tag.destroy
    @ocg.destroy
    @tcg.destroy
    super
  end
  def update
    @roomname_inputbox.update
    @password_inputbox.update
    @lp_inputbox.update
  end
  def name_check
    name = @roomname_inputbox.value
    # P#/PM#/M#/T# 的总房名长度允许为13
    # 其他情况下如果全英文，那么上限19，否则上限20
    # TCG代码自定义房占15个字符
    # 一个汉字两个字符，密码算在内
    if @tcg.checked #代码自定义房
      max = 5
      max -= 1 if name.ascii_only?
    elsif @pvp.checked or @match.checked or @tag.checked
      # 去掉那个#占用的
      max = 12
      max -= 1 if @pvp.checked
      max -= 1 if @match.checked
      max -= 1 if @tag.checked
    else
      max = 20
      max -= 1 if name.ascii_only?
    end
    max -= @lp_inputbox.value.size - 4
    if !@password_inputbox.value.empty?
      max -= 1
      max -= @password_inputbox.value.encode("GBK").bytesize
    end
    max -= name.encode("GBK").bytesize
    return max >= 0
  end
end