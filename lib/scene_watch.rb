#encoding: UTF-8
#==============================================================================
# ■ Scene_Watch
#------------------------------------------------------------------------------
# 　观战
#==============================================================================
require_relative 'scene_duel'
class Scene_Watch < Scene_Duel
  def create_action_window
  end
  def chat(text)
    $game.chat text, $game.room
    Game_Event.push Game_Event::Action.new(Action::Chat.new(true, text), "#{$game.user}:#{text}")
  end
  def action(action)
  end
  def start
    super
    #$game.chat "#{$game.user.name}(#{$game.user.id})进入了观战", @room
  end
  def terminate
    #$game.chat "#{$game.user.name}(#{$game.user.id})离开了观战", @room
  end
  def handle_game(event)
    case event
    when Game_Event::Leave
      Widget_Msgbox.new("离开房间", "观战结束", :ok => "确定") { $scene = Scene_Lobby.new }
    else
      super
    end
  end
end

