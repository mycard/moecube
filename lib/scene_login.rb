#encoding: UTF-8
#==============================================================================
# ■ Scene_Login
#------------------------------------------------------------------------------
# 　login
#==============================================================================
require_relative 'window_gameselect'
require_relative 'window_announcements'
require_relative 'window_login'
require_relative 'scene_replay'
BGM = "title.ogg"
class Scene_Login < Scene
	def start
    WM::set_caption("MyCard", "MyCard")
    @background = Surface.load("graphics/login/background.png").display_format
    $config['game'] = 'iDuel'  #临时修补点击过一次局域网之后无限进入局域网的问题
    @gameselect_window = Window_GameSelect.new(117,269)
    @announcements_window = Window_Announcements.new(313,265,600,24)
    super
	end
  def update
    @announcements_window.update
    #@gameselect_window.update
    super
  end
  def handle_game(event)
    case event
    when Game_Event::Login
      require_relative 'scene_lobby'
      $scene = Scene_Lobby.new
    else
      super
    end
  end
  #def terminate
  #  @gameselect_window.destroy
  #end
end