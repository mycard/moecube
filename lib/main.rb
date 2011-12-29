#!/usr/bin/env ruby
#encoding: UTF-8

begin
  #读取配置文件
  require 'yaml'
  $config = YAML.load_file("config.yml")
  
  #读取命令行参数
  log = "log.log"
  ARGV.each do |arg|
    case arg
    when /--log=(.*)/
      log.replace $1
    end
  end

  #初始化SDL
  require 'sdl'
  include SDL
  SDL.init(INIT_VIDEO | INIT_AUDIO)
  WM::set_caption("MyCard", "graphics/system/icon.gif")
  WM::icon = Surface.load("graphics/system/icon.gif")
  $screen = Screen.open($config["width"], $config["height"], 0, HWSURFACE | ($config["fullscreen"] ? FULLSCREEN : 0))
  Mixer.open(Mixer::DEFAULT_FREQUENCY,Mixer::DEFAULT_FORMAT,Mixer::DEFAULT_CHANNELS,512)
  TTF.init
  
  #初始化标题场景
  require_relative 'scene_title'
  $scene = Scene_Title.new
  
  #初始化日志
  require 'logger'
  if log == "STDOUT" #调试用
    log = STDOUT
    log.set_encoding "GBK", "UTF-8", :invalid => :replace, :undef => :replace if RUBY_PLATFORM["win"] || RUBY_PLATFORM["ming"]
  end
  $log = Logger.new(log)
  $log.info("main"){"初始化成功"}
rescue Exception => exception
  open('error-程序出错请到论坛反馈.txt', 'w'){|f|f.write [exception.inspect, *exception.backtrace].join("\n")}
  exit(1)
end

#主循环
begin
  $scene.main while $scene
rescue Exception => exception
  exception.backtrace.each{|backtrace|break if backtrace =~ /^(.*)\.rb:\d+:in `.*'"$/} #由于脚本是从main.rb开始执行的，总会有个能匹配成功的文件
  $log.fatal($1){[exception.inspect, *exception.backtrace].join("\n")}
  require_relative 'scene_error'
  $scene = Scene_Error.new
  retry
ensure
  $log.close
end