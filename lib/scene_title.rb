#encoding: UTF-8
#==============================================================================
# Scene_Title
#------------------------------------------------------------------------------
# title
#==============================================================================
require_relative 'scene'
require_relative 'widget_inputbox'
require_relative 'window_title'
BGM = 'title.ogg'
class Scene_Title < Scene
  def start
    WM::set_caption("MyCard v#{Update::Version}", "MyCard")
    title = Dir.glob("graphics/titles/title_*.*")
    if $config['screen']['height'] == 640
      title.reject!{|t|t['full']} 
    else
      title.reject!{|t|t['resize']} 
    end
    title = title[rand(title.size)]
    @background = Surface.load(title).display_format
    Surface.blit(@background,0,0,0,0,$screen,0,0)
    buttons_img = "graphics/system/titlebuttons.png"
    if matched = title.match(/title_(\d+)/)
      index = matched[1]
      if File.exist? "graphics/titles/titlebuttons_#{index}.png"
        buttons_img = "graphics/titles/titlebuttons_#{index}.png"
      end
    end

    @command_window = Window_Title.new(title["left"] ? 200 : title["right"] ? 600 : title["special"] ? 42 : 400, title["special"] ? 321 : $config['screen']['height']/2-100,buttons_img)
    (@decision_se = Mixer::Wave.load("audio/se/decision.ogg") if SDL.inited_system(INIT_AUDIO) != 0) rescue nil
    super
  end
  def clear(x,y,width,height)
    Surface.blit(@background,x,y,width,height,$screen,x,y)
  end
  def determine
    return unless @command_window.index
    Mixer.play_channel(-1,@decision_se,0) if @decision_se
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
      require_relative 'scene_login'
      require_relative 'deck'
      load 'lib/ygocore/game.rb' #TODO:不规范啊不规范
      Ygocore.deck_edit
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

