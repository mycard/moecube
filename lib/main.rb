#!/usr/bin/env ruby
begin

  Windows = RUBY_PLATFORM["mswin"] || RUBY_PLATFORM["ming"]
  Font = ['fonts/wqy-microhei.ttc', '/usr/share/fonts/wqy-microhei/wqy-microhei.ttc', '/usr/share/fonts/truetype/wqy/wqy-microhei.ttc', '/Library/Fonts/Hiragino Sans GB W3.otf'].find{|file|File.file? file}
  #System_Encoding = Windows ? "CP#{`chcp`.scan(/\d+$/)}" : `locale |grep LANG |awk -F '=' '{print $2}'`
  
  Dir.glob('post_update_*.rb').sort.each { |file| load file }
  Thread.abort_on_exception = true

  require_relative 'resolution'
  require_relative 'announcement'
  require_relative 'config'
  require_relative 'association'

  #i18n
  require 'i18n'
  require 'locale'
  I18n.load_path += Dir['locales/*.yml']
  I18n::Backend::Simple.include(I18n::Backend::Fallbacks)

  #读取配置文件
  $config = Config.load
  Config.save

  #读取命令行参数
  log       = "log.log"
  log_level = "INFO"
  profile   = nil
  ARGV.each do |arg|
    arg = arg.dup.force_encoding("UTF-8")
    arg.force_encoding("GBK") unless arg.valid_encoding?
    case arg
    when /--log=(.*)/
      log.replace $1
    when /--log-level=(.*)/
      log_level.replace $1
    when /--profile=(.*)/
      profile = $1
    when /^mycard:.*|\.ydk$|\.yrp$|\.deck$/
      require_relative 'quickstart'
      $scene = false
    when /register_association/
      Association.register
      $scene = false
    end
  end

  unless $scene == false
    #加载文件
	  require 'openssl'
    OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE #unsafe
	  require 'digest/sha1'
	  require 'digest/md5'
    require 'logger'
    require 'sdl'
    include SDL

    require_relative 'dialog'
    require_relative 'graphics'
    require_relative 'window'
    require_relative 'widget_msgbox'

    #日志
    if log == "STDOUT" #调试用
      log = STDOUT
    end
    $log       = Logger.new(log, 1, 1024000)
    $log.level = Logger.const_get log_level

    #性能分析
    if profile
      if profile == "STDOUT"
        profile = STDOUT
      else
        profile = open(profile, 'w')
      end
      require 'profiler'
      RubyVM::InstructionSequence.compile_option = {
          :trace_instruction       => true,
          :specialized_instruction => false
      }
      Profiler__::start_profile
    end

    SDL::Event::APPMOUSEFOCUS = 1
    SDL::Event::APPINPUTFOCUS = 2
    SDL::Event::APPACTIVE     = 4
    SDL.putenv ("SDL_VIDEO_CENTERED=1");
    SDL.init(INIT_VIDEO)

    WM::set_caption("MyCard", "MyCard")
    WM::icon = Surface.load("graphics/system/icon.gif")
    $screen  = Screen.open($config['screen']['width'], $config['screen']['height'], 0, HWSURFACE | ($config['screen']['fullscreen'] ? FULLSCREEN : 0))
    TTF.init
    #声音
    begin
      SDL.init(INIT_AUDIO)
      Mixer.open(Mixer::DEFAULT_FREQUENCY, Mixer::DEFAULT_FORMAT, Mixer::DEFAULT_CHANNELS, 1536)
      Mixer.set_volume_music(60)
    rescue
      nil
    end

    #标题场景
    require_relative 'scene_title'
    $scene = Scene_Title.new

    #自动更新, 加载放到SDL前面会崩, 原因不明
    require_relative 'update'
    Update.start
    WM::set_caption("MyCard v#{Update::Version}", "MyCard")

    #文件关联
    Association.start

    #初始化完毕
    $log.info("main") { "初始化成功" }
  end
rescue Exception => exception
  open('error-程序出错请到论坛反馈.txt', 'w') { |f| f.write [exception.inspect, *exception.backtrace].join("\n") }
  $scene = false
end

#主循环
begin
  $scene.main while $scene
rescue ScriptError, StandardError => exception
  exception.backtrace.each { |backtrace| break if backtrace =~ /^(.*)\.rb:\d+:in `.*'"$/ } #由于脚本是从main.rb开始执行的，总会有个能匹配成功的文件
  $log.fatal($1) { [exception.inspect, *exception.backtrace].collect { |str| str.force_encoding("UTF-8") }.join("\n") }
  $game.exit if $game
  require_relative 'scene_error'
  $scene = Scene_Error.new
  retry
ensure
  if profile
    Profiler__::print_profile(profile)
    profile.close
  end
  $log.close rescue nil
end
