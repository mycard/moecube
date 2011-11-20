#encoding: UTF-8

alias gbk_puts puts
def puts(*args)
  gbk_puts(*(args.collect{|item|item.encode "GBK", :invalid => :replace, :undef => :replace}))
end

def p(*args)
  print(args.collect{|item|item.inspect.encode "GBK", :invalid => :replace, :undef => :replace}.join("\n")+"\n") rescue print(args.join("\n")+"\n")
end

def filesize_inspect(size)
  case size
  when 0...1024
    size.to_s + "B"
  when 1024...1024*1024
    (size/1024).to_s + "KB"
  else
    (size/1024/1024).to_s + "MB"
  end
end


require 'sdl'
include SDL
require 'yaml'
$config = YAML.load_file("config.yml") rescue YAML.load_file("data/config_default.yml")

SDL.init(INIT_VIDEO | INIT_AUDIO)
WM::set_caption("iDuel - 享受决斗", "graphics/system/iDuelPanel_32512.ico")
WM::icon = Surface.load("graphics/system/iDuelPanel_32512.ico")

style = HWSURFACE
style |= FULLSCREEN if $config["fullscreen"]
$screen = Screen.open($config["width"], $config["height"], 0, style)

TTF.init

Mixer.open(Mixer::DEFAULT_FREQUENCY,Mixer::DEFAULT_FORMAT,Mixer::DEFAULT_CHANNELS,512)

require_relative 'scene'
require_relative 'window'
require_relative 'window_list'
require_relative 'window_user'
require_relative 'scene_title'

$scene = Scene_Title.new
while $scene
  $scene.main
end
SDL.quit #这货居然会卡一下///囧