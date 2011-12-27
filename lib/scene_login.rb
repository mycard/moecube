#encoding: UTF-8
#==============================================================================
# ■ Scene_Login
#------------------------------------------------------------------------------
# 　login
#==============================================================================
require_relative 'window_gameselect'
require_relative 'window_login'
class Scene_Login < Scene
  Vocab_Logging  = "Logging"
	def start
    #@font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 24)
    #if $config["autologin"]
    #  @username = $config["username"]
    #  @password = $config["password"]
    #  login
    #end
    @background = Surface.load("graphics/login/background.png")
    @gameselect_window = Window_GameSelect.new(117,269)
    @login_window = Window_Login.new(316,316,$config["username"],$config["password"])
	end
	def login
    #@font.draw_blended_utf8($screen, Vocab_Logging, 0,0,255,0,255)
    require_relative 'game'
    require_relative 'iduel/iduel'
    require_relative 'widget_msgbox'
    Widget_Msgbox.new("iduel", "正在登陆")
		$game = Iduel.new
		$game.login(@username, @password)
	end
  #def update
    #while event = Game_Event.poll
    #  handle_game(event)
    #end
    #super
  #end
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

