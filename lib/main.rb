#!/usr/bin/env ruby
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
    File.open(file, "w") { |file| YAML.dump($config, file) }
  end

  def register_url_protocol
    if RUBY_PLATFORM["win"] || RUBY_PLATFORM["ming"]
      require 'win32/registry'
      path, command, icon = assoc_paths
      Win32::Registry::HKEY_CLASSES_ROOT.create('mycard') { |reg| reg['URL Protocol'] = path.ljust path.bytesize }
      Win32::Registry::HKEY_CLASSES_ROOT.create('mycard\shell\open\command') { |reg| reg[nil] = command.ljust command.bytesize }
      Win32::Registry::HKEY_CLASSES_ROOT.create('mycard\DefaultIcon') { |reg| reg[nil] = icon.ljust icon.bytesize }
      Win32::Registry::HKEY_CLASSES_ROOT.create('.ydk') { |reg| reg[nil] = 'mycard' }
      Win32::Registry::HKEY_CLASSES_ROOT.create('.yrp') { |reg| reg[nil] = 'mycard' }
      Win32::Registry::HKEY_CLASSES_ROOT.create('.deck') { |reg| reg[nil] = 'mycard' }
    end
  end

  def assoc_paths
    pwd = Dir.pwd.gsub('/', '\\')
    path = '"' + pwd + '\ruby\bin\rubyw.exe" -C"' + pwd + '" -KU lib/main.rb'
    command = path + ' "%1"'
    icon = '"' + pwd + '\mycard.exe", 0'
    [path, command, icon]
  end

  def assoc_need?
    return false unless RUBY_PLATFORM["win"] || RUBY_PLATFORM["ming"]
    return false if $config['no_assoc']
    path, command, icon = assoc_paths
    require 'win32/registry'
    begin
      Win32::Registry::HKEY_CLASSES_ROOT.open('mycard') { |reg| return true unless reg['URL Protocol'] == path }
      Win32::Registry::HKEY_CLASSES_ROOT.open('mycard\shell\open\command') { |reg| return true unless reg[nil] == command }
      Win32::Registry::HKEY_CLASSES_ROOT.open('mycard\DefaultIcon') { |reg| return true unless reg[nil] == icon }
      Win32::Registry::HKEY_CLASSES_ROOT.open('.ydk') { |reg| return true unless reg[nil] == 'mycard' }
      Win32::Registry::HKEY_CLASSES_ROOT.open('.yrp') { |reg| return true unless reg[nil] == 'mycard' }
      Win32::Registry::HKEY_CLASSES_ROOT.open('.deck') { |reg| return true unless reg[nil] == 'mycard' }
    rescue
      return true
    end
  end

  def request_assoc
    require_relative 'widget_msgbox'
    Widget_Msgbox.new("mycard", "即将进行文件关联, 弹出安全警告请点允许", ok: "确定", cancel: "取消") do |clicked|
      if clicked == :ok
        yield
      else
        Widget_Msgbox.new("mycard", "没有进行关联,要重新关联请删除config.yml")
        $config['no_assoc'] = true
        save_config
      end
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
      when /register_web_protocol/
        $assoc_requested = true
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
    Mixer.open(Mixer::DEFAULT_FREQUENCY, Mixer::DEFAULT_FORMAT, Mixer::DEFAULT_CHANNELS, 1024)
    Mixer.set_volume_music(60)
    TTF.init
    Thread.abort_on_exception = true

    #初始化日志
    require 'logger'
    if log == "STDOUT" #调试用
      log = STDOUT
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
    require_relative 'dialog'
    $scene = Scene_Title.new

    #自动更新
    require_relative 'update'
    Update.start
    WM::set_caption("MyCard v#{Update::Version}", "MyCard")
    if assoc_need?
      request_assoc do
        register_url_protocol rescue Dialog.uac("ruby/bin/rubyw.exe", "-KU lib/main.rb register_web_protocol")
      end
    end

    $log.info("main") { "初始化成功" }
  end
rescue Exception => exception
  open('error-程序出错请到论坛反馈.txt', 'w') { |f| f.write [exception.inspect, *exception.backtrace].join("\n") }
  $scene = false
end

#主循环
begin
  $scene.main while $scene
rescue Exception => exception
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