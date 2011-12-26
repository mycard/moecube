#==============================================================================
# ■ Scene_Base
#------------------------------------------------------------------------------
# 　游戏中全部画面的超级类。
#==============================================================================
require 'fpstimer'
class Scene
  attr_reader :windows
  attr_reader :background
  @@fpstimer = FPSTimer.new
  #--------------------------------------------------------------------------
  # ● 主处理
  #--------------------------------------------------------------------------
  def main
    start
    while $scene == self
      update
      @@fpstimer.wait_frame do
        if @background
          $screen.put(@background,0,0)
        else
          $screen.fill_rect(0, 0, $screen.w, $screen.h, 0x000000)
        end
        @windows.each do |window|
          window.draw($screen)
        end
        @font.draw_blended_utf8($screen, "%.1f" % @@fpstimer.real_fps, 0, 0, 0xFF, 0xFF, 0xFF)
        $screen.update_rect(0,0,0,0)
      end
    end
    terminate
  end
  def initialize
    @windows = []
    @font = TTF.open('fonts/WenQuanYi Micro Hei.ttf', 16)
  end
  #--------------------------------------------------------------------------
  # ● 开始处理
  #--------------------------------------------------------------------------
  def start

  end
  def refresh_rect(x, y, width, height, background=@background, ox=0,oy=0)
    Surface.blit(background,x+ox,y+oy,width,height,$screen,x,y)
    yield
    $screen.update_rect(x, y, width, height)
  end
  #--------------------------------------------------------------------------
  # ● 执行渐变
  #--------------------------------------------------------------------------
  def perform_transition
    Graphics.transition(10)
  end
  #--------------------------------------------------------------------------
  # ● 开始後处理
  #--------------------------------------------------------------------------
  def post_start
  end
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  def update
    while event = Event.poll
      handle(event)
    end
  end
  def handle(event)
    case event
    when Event::MouseMotion
      update_active_window(event.x, event.y)
    when Event::MouseButtonDown
      update_active_window(event.x, event.y)
      case event.button
      when Mouse::BUTTON_LEFT
        @active_window.clicked if @active_window
      when 4
        @active_window.cursor_up
      when 5
        @active_window.cursor_down
      end
    when Event::Quit
      $scene = nil
    end
  end
  #--------------------------------------------------------------------------
  # ● 结束前处理
  #--------------------------------------------------------------------------
  def pre_terminate
  end
  #--------------------------------------------------------------------------
  # ● 结束处理
  #--------------------------------------------------------------------------
  def terminate
    #$screen.fill_rect(0,0,$screen.w, $screen.h, 0xFF000000)
  end
  def update_active_window(x, y)
    self.windows.reverse.each do |window|
      if window.include?(x, y) && window.visible
        if window != @active_window
          @active_window.lostfocus(window) if @active_window
          @active_window = window 
        end
        @active_window.mousemoved(x, y)
        return @active_window
      end
    end
    if @active_window
      @active_window.lostfocus
      @active_window = nil
    end
  end
end

