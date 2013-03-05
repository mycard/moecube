#encoding: UTF-8
#==============================================================================
# ■ Window_Roomitems
#------------------------------------------------------------------------------
# 　大厅内房间列表
#==============================================================================
require_relative 'window_scrollable'
require_relative 'window_join'
class Window_RoomList < Window_Scrollable
	attr_reader :items
  WLH = 48
	def initialize(x, y, items)
    @button = Surface.load('graphics/lobby/room.png')
    @button.set_alpha(RLEACCEL, 255)
    #@background = Surface.load 'graphics/lobby/roomitems.png'
    #@contents = Surface.load 'graphics/lobby/roomitems.png'
    super(x,y,@button.w / 3, ($config['screen']['height'] - 288) / 48 * 48)
    @item_max = 0
    @font = TTF.open(Font, 16)
    @color = [0x03, 0x11, 0x22]
    @scrollbar = Widget_ScrollBar.new(self,@x+@width,@y,@height)
    self.items = items
	end

  def draw_item(index, status=0)
    y = item_rect(index)[1]
    room = @items[index]
    Surface.blit(@button, @width*status, room.full? ? WLH : 0, @width, WLH, @contents, 0, y)
    @font.draw_blended_utf8(@contents, room.id.to_s, 24, y+8, *@color) unless room.id.to_s.empty?
    @font.draw_blended_utf8(@contents, room.full? ? "【决斗中】" : room.private? ? "【私密房】" : "【等待中】", 8, y+24, *@color)
    @font.draw_blended_utf8(@contents, room.name, 128, y+8, *room.color) unless room.name.nil? or room.name.empty? or room.name.size > 100
    @font.draw_blended_utf8(@contents, room.player1.name, 128, y+24, *room.player1.color) if room.player1 and !room.player1.name.empty?
    @font.draw_blended_utf8(@contents, room.player2.name, 320, y+24, *room.player2.color) if room.player2 and !room.player2.name.empty?
    room.extra.each_with_index do |extra, index|
      str, color = extra
      @font.draw_blended_utf8(@contents, str, 300+index*96, y+8, *color)
    end
  end
  def update
    @join_window.update if @join_window and !@join_window.destroyed?
  end
  def mousemoved(x,y)
    return unless self.include?(x,y)
    self.index = (y - @y) / WLH + @scroll
  end
  def clicked
    return unless @index and room = @items[@index]
    if room.full?
      @joinroom_msgbox = Widget_Msgbox.new("加入房间", "正在加入观战")
      $game.watch room
    else
      if room.private
        @join_window = Window_Join.new(0,0,room)
      else
        @joinroom_msgbox = Widget_Msgbox.new("加入房间", "正在加入房间")
        $game.join room
      end
    end
  end
end