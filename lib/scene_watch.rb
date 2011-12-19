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
  def handle_game(event)
    case event
    when Game_Event::Leave
      Widget_Msgbox.new("离开房间", "观战结束") { $scene = Scene_Hall.new  }
    else
      super
    end
  end
end

