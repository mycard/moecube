#==============================================================================
# ■ Scene_Login
#------------------------------------------------------------------------------
# 　login
#==============================================================================

class Scene_Login < Scene
  Vocab_Logging  = "Logging"
	def start
    require_relative 'iduel'
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 24)
    if $config["autologin"]
      @username = $config["username"]
      @password = $config["password"]
      login
    end
	end
	def login
    
    @font.draw_blended_utf8($screen, Vocab_Logging, 0,0,255,0,255)
    $screen.update_rect(0,0,100,24)
		
		$iduel = Iduel.new
		$iduel.login(@username, @password)
	end
  def update
    while event = Event.poll
      case event
      when Event::Quit
        $scene = nil
      end
    end

    while event = Iduel::Event.poll
      case event
      when Iduel::Event::LOGINOK
        require_relative 'scene_hall'
        $scene = Scene_Hall.new
      else
        p event
      end
    end
  end
end
