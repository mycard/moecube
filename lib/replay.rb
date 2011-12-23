class Replay
  ReplayPath = 'replay'
  LastReplay = 'lastreplay.txt'
  def initialize(filename=LastReplay)
    @file = open(File.expand_path(filename, ReplayPath), 'w') unless filename.is_a? IO
  end
  def save(filename="#{Time.now.strftime("%Y-%m-%d_%H:%M-%S")}_#{$game.room.player1.name}(#{$game.room.player1.id})_#{$game.room.player2.name}(#{$game.room.player2.id}).txt")
    close
    File.rename(@file.path, File.expand_path(filename, ReplayPath))
  end
  def close
    @file.close
  end
  def self.load(file)
    @file = open(file)
  end
  def add(action)
    #协议定义
  end
  def get
    #协议定义
  end
  def eof?
    @file.eof?
  end
end