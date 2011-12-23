class Scene_Single < Scene
  require 'Scene_Replay'
  require_relative 'iduel/iduel'
  def start
    $game = Iduel.new
    $scene = Scene_Replay.new Replay.load("E:/game/yu-gi-oh/test_rep.txt")
  end
end
