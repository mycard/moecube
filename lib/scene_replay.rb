#encoding: UTF-8
require 'scene_watch'
class Scene_Replay < Scene_Watch
  def initialize(replay)
    @replay = replay
    @count = 0
    super(@replay.room)
  end
  def init_replay
  end
  def save_replay
  end
  def update
    if @count >= 10#60
      event = @replay.get
      if event
        Game_Event.push event
        @count = 0
      else
        Widget_Msgbox.new("回放", "战报回放完毕", :ok => "确定") { $scene = Scene_Login.new }
      end
    end
    @count += 1
    super
  end
end
