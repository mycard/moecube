#encoding: UTF-8
#==============================================================================
# ■ Scene_Login
#------------------------------------------------------------------------------
# 　login
#==============================================================================
require_relative 'window_gameselect'
require_relative 'window_login'
require 'game'
class Scene_Login < Scene
  Vocab_Logging  = "Logging"
	def start
    @background = Surface.load("graphics/login/background.png")
    @gameselect_window = Window_GameSelect.new(117,269,$config["game"])
	end
  def update
    while event = Game_Event.poll
      handle_game(event)
    end
    super
  end
  def handle_game(event)
    case event
    when Game_Event::Login
      require_relative 'scene_hall'
      $scene = Scene_Hall.new
    when Game_Event::Error
      Widget_Msgbox.new(event.title, event.message, :ok => "确定"){$scene = Scene_Title.new}
    else
      $log.debug event
    end
  end
end