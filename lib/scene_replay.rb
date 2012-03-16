require_relative 'scene_watch'
class Scene_Replay < Scene_Watch
  def initialize(replay)
    @replay = replay
    @count = 0
    super(@replay.room)
    $log.info('scene_reply'){'inited'}
  end
  def init_replay
  end
  def save_replay
  end
  def update
    if @count and @count >= 60
      event = @replay.get
      if event
        Game_Event.push event
        @count = 0
      else
        Widget_Msgbox.new("回放", "战报回放完毕", :ok => "确定") { $scene = Scene_Login.new }
        @count = nil #播放完毕标记
      end
    end
    @count += 1 if @count
    super
  end
end
