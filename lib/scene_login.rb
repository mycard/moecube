#encoding: UTF-8
#==============================================================================
# ■ Scene_Login
#------------------------------------------------------------------------------
# 　login
#==============================================================================
require_relative 'window_gameselect'
require_relative 'window_login'
require_relative 'scene_replay'
class Scene_Login < Scene
	def start
    @background = Surface.load("graphics/login/background.png").display_format
    @gameselect_window = Window_GameSelect.new(117,269,$config["game"])
	end
  #def handle(event)
  #  case event
  #  when Event::Active
  #    if event.gain
  #  end
  #end
  def handle_game(event)
    case event
    when Game_Event::Login
      require_relative 'scene_lobby'
      $scene = Scene_Lobby.new
    else
      super
    end
  end
end