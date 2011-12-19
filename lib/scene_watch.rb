#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================
require_relative 'scene_duel'
class Scene_Watch < Scene_Duel
  def create_action_window
  end
  def action(action)
    action.run
  end
end

