#encoding: UTF-8
#==============================================================================
# 鈻�Scene_Title
#------------------------------------------------------------------------------
# 銆�itle
#==============================================================================
class Scene_Title < Scene
  require_relative 'window_title'
  require_relative 'widget_inputbox'
  def start
    
    title = Dir.glob("graphics/titles/title_*.*")
    title = title[rand(title.size)]
    @background = Surface.load(title)
    Surface.blit(@background,0,0,0,0,$screen,0,0)
    @command_window = Window_Title.new(title["left"] ? 200 : title["right"] ? 600 : 400, 300)
    
    @logo = Surface.load("graphics/system/logo.png")
    Surface.blit(@logo,0,0,0,0,$screen,@command_window.x-(@logo.w-@command_window.width)/2,150)
    $screen.update_rect(0,0,0,0)
    @bgm = Mixer::Music.load 'audio/bgm/title.ogg'
    @decision_se = Mixer::Wave.load("audio/se/decision.ogg")
    Mixer.fade_in_music @bgm, -1, 800
    super
    
  end
  def clear(x,y,width,height)
    Surface.blit(@background,x,y,width,height,$screen,x,y)
  end
  def update
    while event = Event.poll
      case event
      when Event::MouseMotion
        if @command_window.include?(event.x, event.y)
          @command_window.index = (event.y - @command_window.y) / @command_window.class::Button_Height
        else
          @command_window.index = nil
        end
      when Event::MouseButtonDown

        
        case event.button
        when Mouse::BUTTON_LEFT
          
          if @command_window.include?(event.x, event.y)
            @command_window.click((event.y - @command_window.y) / @command_window.class::Button_Height)
          end
        when Mouse::BUTTON_RIGHT
        when 4 #scrool_up
          @command_window.index = @index ? (@index-1) % Buttons.size : 0
        when 5
          @command_window.index = @index ? (@index+1) % Buttons.size : 0
        end
      when Event::MouseButtonUp
        case event.button
        when Mouse::BUTTON_LEFT
          if @command_window.include?(event.x, event.y)
            @command_window.index = (event.y - @command_window.y) / @command_window.class::Button_Height
            determine
          end
        end
      when Event::KeyDown
        case event.sym
        when Key::UP
          @command_window.index = @index ? (@index-1) % Buttons.size : 0
        when Key::DOWN
          @command_window.index = @index ? (@index+1) % Buttons.size : 0
        when Key::RETURN
          if @index
            @command_window.click(@index)
          end
        end
      when Event::KeyUp
        case event.sym
        when Key::RETURN
          determine
        end
      when Event::Quit
        $scene = nil
      else
        p event
      end
    end
    #super #黑历史，title在有那架构之前就已经写好了，暂时懒得动
  end
  def determine
    return unless @command_window.index
    Mixer.play_channel(-1,@decision_se,0)
    $scene = case @command_window.index
    when 0
      require_relative 'scene_login'
      Scene_Login.new
    when 1
      require_relative 'scene_hall_nbx'
      Scene_Hall_NBX.new
    when 2
      require_relative 'scene_deck'
      Scene_Deck.new
    when 3
      require_relative 'scene_config'
      Scene_Config.new
    when 4
      nil
    end
  end
  def terminate
    @command_window.destroy
    @background.destroy 
    $screen.fill_rect(0, 0, $screen.w, $screen.h, 0x00000000)
    $screen.update_rect(0,0,0,0)
  end
end

