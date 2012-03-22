class Scene_Lobby
  def join(room)
    Ygocore.run_ygocore(room)
  end
end
