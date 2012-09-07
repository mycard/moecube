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
    @background = Graphics.load('login', 'background', false)
	#======================================================
	# We'll pay fpr that soon or later.
	#======================================================
	if $config['screen']['height'] == 768
		@gameselect_window = Window_GameSelect.new(117,269)
	elsif $config['screen']['height'] == 640
		@gameselect_window = Window_GameSelect.new(117,134)
	else
		raise "无法分辨的分辨率"
	end	
	#======================================================
	# ENDS HERE
	#======================================================
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