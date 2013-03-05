class Window_Filter < Window
  attr_reader :index
  def initialize(x,y)
    @background = Surface.load('graphics/lobby/filter.png').display_format
    super(x,y, @background.w, @background.h)
    @font = TTF.open(Font, 16)
    @color = [0x04, 0x47, 0x7c]
    @title_color = [0xFF, 0xFF, 0xFF]


    @servers = $game.servers.each_with_index.collect do |server, index|
      result = Widget_Checkbox.new(self, 4+@x,@y+WLH+WLH*index,@width-8,24,true,server.name){|checked|checked ? $game.filter[:servers].push(server) : $game.filter[:servers].delete(server) ; Game_Event.push(Game_Event::AllRooms.new($game.rooms))}
      result.background = @background.copy_rect(4,WLH+WLH*index,@width-8,24)
      result.checked = $game.filter[:servers].include? server
      result.refresh
      result
    end

    @waiting_only = Widget_Checkbox.new(self, 4+@x,@y+WLH*7-4,@width-8,24,true, I18n.t('lobby.waiting_only')){|checked|$game.filter[:waiting_only] = checked; Game_Event.push(Game_Event::AllRooms.new($game.rooms))}
    @waiting_only.background = @background.copy_rect(4,WLH*7-4,@width-8,24)
    @waiting_only.checked = false
    @waiting_only.refresh

    @normal_only = Widget_Checkbox.new(self, 4+@x,@y+WLH*7+WLH-4,120,24,true,I18n.t('lobby.normal_only')){|checked|$game.filter[:normal_only] = checked; Game_Event.push(Game_Event::AllRooms.new($game.rooms))}
    @normal_only.background = @background.copy_rect(4,WLH*7+WLH-4,120,24)
    @normal_only.checked = false
    @normal_only.refresh
    refresh
  end
  def refresh
    clear
    @font.draw_blended_utf8(@contents, "服务器", 4, 4, *@color)
    @contents.fill_rect(4,WLH,@contents.w-8, 2, 0xAA0A7AC5)
    @font.draw_blended_utf8(@contents, "房间属性", 4, WLH*6+4-4, *@color)
    @contents.fill_rect(4,WLH*7-4,@contents.w-8, 2, 0xAA0A7AC5)
  end
  def destroy
    @servers.each{|server|server.destroy}
    @normal_only.destroy
    @waiting_only.destroy
    super
  end
end