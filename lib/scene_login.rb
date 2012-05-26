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
require_relative 'scene_lobby'
class Scene_Login < Scene
	def start
    WM::set_caption("MyCard v#{Update::Version}", "MyCard")
    @background = Surface.load("graphics/login/background.png").display_format
    @gameselect_window = Window_GameSelect.new(117,269)
    super
	end
  def update
    @gameselect_window.update
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