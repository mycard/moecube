#!/usr/bin/env ruby
p ARGV
STDIN.gets
begin
  #定义全局方法
  def load_config(file="config.yml")
    require 'yaml'
    $config = YAML.load_file("config.yml") rescue {}
    $config = {} unless $config.is_a? Hash
    $config['bgm'] = true if $config['bgm'].nil?
    $config['screen'] ||= {}
    $config['screen']['width'] ||= 1024
    $config['screen']['height'] ||= 768
  end
  def save_config(file="config.yml")
    File.open(file,"w"){|file| YAML.dump($config, file)}
  end
  def register_url_protocol
    if RUBY_PLATFORM["win"] || RUBY_PLATFORM["ming"]
      require 'win32/registry'
      pwd = Dir.pwd.gsub('/', '\\')
      path = '"' + pwd + '\ruby\bin\ruby.exe" -C"' + pwd + '" -KU lib/main.rb'
      command = path + ' "%1"'
      Win32::Registry::HKEY_CLASSES_ROOT.create('mycard'){|reg|reg['URL Protocol'] = path unless (reg['URL Protocol'] == path rescue false)}
      Win32::Registry::HKEY_CLASSES_ROOT.create('mycard\shell\open\command'){|reg|reg[nil] = command unless (reg[nil] == command rescue false)}
    end
  end
  Thread.abort_on_exception = true
  require_relative 'announcement'
  #读取配置文件
  load_config
  save_config
  
  #读取命令行参数
  log = "log.log"
  log_level = "INFO"
  profile = nil
  ARGV.each do |arg|
    p arg
    STDIN.gets
    case arg.dup.force_encoding("UTF-8")
    when /--log=(.*)/
      log.replace $1
    when /--log-level=(.*)/
      log_level.replace $1
    when /--profile=(.*)/
      profile = $1
    when /mycard:.*/
      require_relative 'quickstart'
      $scene = false
    when /register_web_protocol/
      register_url_protocol
      $scene = false
    end
  end
  unless $scene == false
    #初始化SDL
    require 'sdl'
    include SDL
    SDL::Event::APPMOUSEFOCUS = 1
    SDL::Event::APPINPUTFOCUS = 2
    SDL::Event::APPACTIVE = 4
    SDL.putenv ("SDL_VIDEO_CENTERED=1");
    SDL.init(INIT_VIDEO | INIT_AUDIO)
    WM::set_caption("MyCard", "MyCard")
    WM::icon = Surface.load("graphics/system/icon.gif")
    $screen = Screen.open($config['screen']['width'], $config['screen']['height'], 0, HWSURFACE | ($config['screen']['fullscreen'] ? FULLSCREEN : 0))
    Mixer.open(Mixer::DEFAULT_FREQUENCY,Mixer::DEFAULT_FORMAT,Mixer::DEFAULT_CHANNELS,1024)
    Mixer.set_volume_music(60)
    TTF.init
    Thread.abort_on_exception = true
  
    #初始化日志
    require 'logger'
    if log == "STDOUT" #调试用
      log = STDOUT
      STDOUT.set_encoding "GBK", "UTF-8", :invalid => :replace, :undef => :replace if RUBY_PLATFORM["win"] || RUBY_PLATFORM["ming"]
    end
    $log = Logger.new(log)
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
        :trace_instruction => true,
        :specialized_instruction => false
      }
      Profiler__::start_profile
    end

  
    #初始化标题场景
    require_relative 'scene_title'
    $scene = Scene_Title.new
  
    #自动更新
    require_relative 'update'
    Update.start
    WM::set_caption("MyCard v#{Update::Version}", "MyCard")
    require_relative 'dialog'
    register_url_protocol rescue Dialog.uac("ruby/bin/rubyw.exe", "-KU lib/main.rb register_web_protocol")
    $log.info("main"){"初始化成功"}
  end
rescue Exception => exception
  open('error-程序出错请到论坛反馈.txt', 'w'){|f|f.write [exception.inspect, *exception.backtrace].join("\n")}
  $scene = false
end

#主循环
begin
  $scene.main while $scene
rescue Exception => exception
  exception.backtrace.each{|backtrace|break if backtrace =~ /^(.*)\.rb:\d+:in `.*'"$/} #由于脚本是从main.rb开始执行的，总会有个能匹配成功的文件
  $log.fatal($1){[exception.inspect, *exception.backtrace].collect{|str|str.force_encoding("UTF-8")}.join("\n")}
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