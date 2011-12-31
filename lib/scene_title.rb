#encoding: UTF-8
#==============================================================================
# 鈻�Scene_Title
#------------------------------------------------------------------------------
# 銆�itle
#==============================================================================
require_relative 'scene'
require_relative 'window_title'
class Scene_Title < Scene
  def start
    title = Dir.glob("graphics/titles/title_*.*")
    title = title[rand(title.size)]
    @background = Surface.load(title).display_format
    Surface.blit(@background,0,0,0,0,$screen,0,0)
    @command_window = Window_Title.new(title["left"] ? 200 : title["right"] ? 600 : 400, 300)
    #logo = Surface.load("graphics/system/logo.png")
    #@logo_window = Window.new(@command_window.x-(logo.w-@command_window.width)/2,150,logo.w,logo.h)
    #@logo_window.contents = logo
    #$screen.update_rect(0,0,0,0)
    @bgm = Mixer::Music.load 'audio/bgm/title.ogg'
    @decision_se = Mixer::Wave.load("audio/se/decision.ogg")
    Mixer.fade_in_music @bgm, -1, 800
    super
    
  end
  def clear(x,y,width,height)
    Surface.blit(@background,x,y,width,height,$screen,x,y)
  end
  def determine
    return unless @command_window.index
    Mixer.play_channel(-1,@decision_se,0)
    case @command_window.index
    when 0
      require_relative 'scene_login'
      $scene = Scene_Login.new
    when 1
      #require_relative 'scene_single'
      require_relative 'widget_msgbox'
      Widget_Msgbox.new("mycard", "功能未实现", :ok => "确定")
      #Scene_Single.new
    when 2
      require_relative 'widget_msgbox'
      Widget_Msgbox.new("mycard", "功能未实现", :ok => "确定")
      #require_relative 'scene_deck'
      #Scene_Deck.new
    when 3
      require_relative 'scene_config'
      $scene = Scene_Config.new
    when 4
      $scene = nil
    end
  end
  def terminate
    @command_window.destroy
    @background.destroy
    super
  end
end

