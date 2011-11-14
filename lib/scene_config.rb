#==============================================================================
# ■ Scene_Config
#------------------------------------------------------------------------------
# 　config
#==============================================================================

class Scene_Config < Scene
  require_relative 'window_config'
	def start
    @background = Surface.load "graphics/config/background.png"
    @config_window = Window_Config.new(0,0)
    #全屏模式
    #p $config
    #
    #
    #
    #

    #$scene = Scene_Title.new
	end
  def handle(event)
    case event
    when Event::MouseMotion
      self.windows.reverse.each do |window|
        if window.include? event.x, event.y
          @active_window = window 
          @active_window.mousemoved(event.x, event.y)
          break
        end
      end
    when Event::MouseButtonDown
      case event.button
      when Mouse::BUTTON_LEFT
        @active_window.mousemoved(event.x, event.y)
        @active_window.clicked
      when 4
        @active_window.cursor_up
      when 5
        @active_window.cursor_down
      end
    else
      super
    end
  end
end