#==============================================================================
# ■ Scene_Base
#------------------------------------------------------------------------------
# 　游戏中全部画面的超级类。
#==============================================================================

class Scene
  attr_reader :windows
  attr_reader :background
  #--------------------------------------------------------------------------
  # ● 主处理
  #--------------------------------------------------------------------------
  def main
    start
    while $scene == self
      update
    end
    terminate
  end
  def initialize
    @windows = []
  end
  #--------------------------------------------------------------------------
  # ● 开始处理
  #--------------------------------------------------------------------------
  def start
    @fps = Window.new(0,0,100,24,500)
    @font = TTF.open('fonts/WenQuanYi Micro Hei.ttf', 16)
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
    #@fps.clear(0,0,100,24)
    #@font.draw_blended_utf8(@fps.contents, @fpscount, 160, 12, 0x00,0x00,0x00)
    #@fpscount += 1
    $fpstimer.wait_frame do
      $screen.put(@background,0,0)
      @fps.contents.fill_rect(0,0,@fps.contents.w,@fps.contents.h,0x00000000)
      @font.draw_solid_utf8(@fps.contents, "%.1f" % $fpstimer.real_fps, 0, 0, 0xFF, 0xFF, 0xFF)
      @windows.each do |window|
        if window.contents && window.visible && !window.destroted?
          if window.angle.zero?
            Surface.blit(window.contents, *window.viewport, $screen, window.x, window.y) 
          else
            contents = window.contents.transform_surface(0x66000000,180,1,1,0)
            Surface.blit(contents, *window.viewport, $screen, window.x, window.y)
            #Surface.transform_blit(window.contents,$screen,0,1,1,100,100,100,100,Surface::TRANSFORM_AA)#,0,0)
          end
        end
        #$screen.put(window.contents, window.x, window.y) if window.contents && window.visible
      end
      $screen.update_rect(0,0,0,0)
    end
  end
  def handle(event)
    case event
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
end

