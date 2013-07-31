#encoding: UTF-8
#==============================================================================
# ■ Scene_Base
#------------------------------------------------------------------------------
# 　游戏中全部画面的超级类。
#==============================================================================
require_relative 'fpstimer'
require_relative 'game'
require_relative 'window_bgm'
require 'ogginfo'
require_relative 'widget_inputbox'
class Scene
  attr_reader :windows
  attr_reader :background
  @@fpstimer = FPSTimer.new
  @@last_bgm = @@bgm = nil
  #--------------------------------------------------------------------------
  # ● 主处理
  #--------------------------------------------------------------------------
  def initialize
    @background = nil
    @windows = []
    @active_window = nil
    @font = TTF.open(Font, 16)
  end
  def main
    start
    while $scene == self
      update
      @@fpstimer.wait_frame{draw}
    end
    terminate
  end
  def draw
    if @background
      $screen.put(@background,0,0)
    else
      $screen.fill_rect(0, 0, $screen.w, $screen.h, 0x000000)
    end
    @windows.each do |window|
      window.draw($screen)
    end
    if Update.status
      @font.draw_blended_utf8($screen, Update.status, 0, 0, 0xFF, 0xFF, 0xFF) 
    else
      @font.draw_blended_utf8($screen, "%.1f" % @@fpstimer.real_fps, 0, 0, 0xFF, 0xFF, 0xFF)
    end
    $screen.update_rect(0,0,0,0)
  end
  #--------------------------------------------------------------------------
  # ● 开始处理
  #--------------------------------------------------------------------------
  def start
    if $config['bgm'] and @@last_bgm != bgm and SDL.inited_system(INIT_AUDIO) != 0 and File.file? "audio/bgm/#{bgm}"
      @@bgm.destroy if @@bgm
      @@bgm = Mixer::Music.load "audio/bgm/#{bgm}"
      Mixer.fade_in_music(@@bgm, -1, 800)
      title = OggInfo.new("audio/bgm/#{bgm}").tag["title"]
      @bgm_window = Window_BGM.new title if title and !title.empty?
      @@last_bgm = bgm
    end rescue nil
  end
  def bgm
    "title.ogg"
  end
  def last_bgm
    @@last_bgm
  end
  def last_bgm=(bgm)
    @@last_bgm = bgm
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
    @bgm_window.update if @bgm_window and !@bgm_window.destroyed?
    while event = Event.poll
      handle(event)
    end
    #要不要放到一个Scene_Game里来处理这个？
    while event = Game_Event.poll
      handle_game(event)
    end
  end
  def handle(event)
    case event
    when Event::MouseMotion
      update_active_window(event.x, event.y)
    when Event::MouseButtonDown
      case event.button
      when Mouse::BUTTON_LEFT
        update_active_window(event.x, event.y)
        @active_window.clicked if @active_window
        if !(@active_window.is_a? Widget_InputBox)
          Widget_InputBox.focus = false
        end
      when 4
        @active_window.scroll_up if @active_window
      when 5
        @active_window.scroll_down if @active_window
      end
    when Event::MouseButtonUp
      case event.button
      when Mouse::BUTTON_LEFT
        update_active_window(event.x, event.y)
        @active_window.mouseleftbuttonup if @active_window
      end
    when Event::KeyDown
      case event.sym
      when Key::RETURN
        if event.mod & Key::MOD_ALT != 0
          $config['screen']['fullscreen'] = !$config['screen']['fullscreen']
          $screen.destroy
          style = HWSURFACE
          style |= FULLSCREEN if $config['screen']["fullscreen"]
          $screen = Screen.open($config['screen']["width"], $config['screen']["height"], 0, style)
          Config.save
        end
      when Key::F12
        $scene = Scene_Title.new
      else
        #$log.info('unhandled event'){event.inspect}
      end
    when Event::Quit
      $scene = nil
    when Event::Active
      if (event.state & Event::APPINPUTFOCUS) != 0
        Widget_InputBox.focus = event.gain
      end
    else
      #$log.info('unhandled event'){event.inspect}
    end
  end
  def handle_game(event)
    case event
    when Game_Event::Error
      if event.fatal
        Widget_Msgbox.new(event.title, event.message, :ok => "确定"){$game.exit if $game;$scene = Scene_Login.new}
      else
        Widget_Msgbox.new(event.title, event.message, :ok => "确定")
      end
    else
      $log.debug('未处理的游戏事件'){event.inspect}
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
    self.windows.each{|window|window.destroy}
  end
  def update_active_window(x, y)
    self.windows.reverse.each do |window|
      if window.include?(x, y) && window.visible
        if window != @active_window
          @active_window.lostfocus(window) if @active_window and !@active_window.destroyed?
          @active_window = window 
        end
        @active_window.mousemoved(x, y)
        return @active_window
      end
    end
    if @active_window and !@active_window.destroyed?
      @active_window.lostfocus
      @active_window = nil
    end
  end
end

