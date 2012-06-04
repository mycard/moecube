#encoding: UTF-8
#==============================================================================
# ■ Scene_Config
#------------------------------------------------------------------------------
# 　config
#==============================================================================

class Scene_Config < Scene
  require_relative 'window_config'
  BGM = 'title.ogg'
	def start
    @background = Surface.load("graphics/config/background.png").display_format
    @config_window = Window_Config.new(0,0)
    super
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