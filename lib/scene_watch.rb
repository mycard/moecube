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
  def action(action)
  end
  def start
    super
    action = Action::Chat.new(true, "#{$game.user.name}(#{$game.user.id})进入了观战")
    action.id = :观战
    $game.action action
  end
  def handle(event)
    case event
    when Event::KeyDown
      case event.sym
      when Key::F10
        action = Action::Chat.new(true, "#{$game.user.name}(#{$game.user.id})离开了观战")
        action.id = :观战
        $game.action action
        $game.leave
      else
        super
      end
    else
      super
    end
  end
  def handle_game(event)
    case event
    when Game_Event::Leave
      Widget_Msgbox.new("离开房间", "观战结束", :ok => "确定") { $scene = Scene_Hall.new }
    else
      super
    end
  end
end

