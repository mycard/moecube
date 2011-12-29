class Replay
  ReplayPath = 'replay'
  LastReplay = 'lastreplay.txt'
  def initialize(filename=LastReplay)
    @file = open(File.expand_path(filename, ReplayPath), 'w') unless filename.is_a? IO
  end
  def add(action)
    action = action.escape if action.is_a? Action
    @file.write action + "\n"
  end
  def save(filename="#{$game.room.player1.name}(#{$game.room.player1.id})_#{$game.room.player2.name}(#{$game.room.player2.id})_#{Time.now.strftime("%m%d%H%M")}.txt")
    close
    File.rename(@file.path, File.expand_path(filename, ReplayPath))
  end
  def close
    @file.close
  end
end
