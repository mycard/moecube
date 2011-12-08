#==============================================================================
# ■ Scene_Login
#------------------------------------------------------------------------------
# 　login
#==============================================================================

class Scene_Single < Scene
  Vocab_Logging  = "Logging"
	def start
    require_relative 'nbx/nbx'
		$game = NBX.new
    login
	end
	def login
    username = $config['username'] && !$config['username'].empty? ? $config['username'] : $_ENV['username']
    $game.login username
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
    end
  end
end
