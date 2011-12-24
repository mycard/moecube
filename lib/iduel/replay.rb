#encoding: UTF-8
class Replay
  Delimiter = /^.+?\(\d+\)\(\d+:\d+:\d+\):   (?:\r)?\n /
  Player_Filter = /^(.+?)\((\d+)\)\(\d+:\d+:\d+\):   (?:\r)?\n \[\d+\] ◎→/
  Opponent_Filter =/^(.+?)\((\d+)\)\(\d+:\d+:\d+\):   (?:\r)?\n \[\d+\] ●→/
  attr_accessor :room, :player1, :player2, :actions
  def add(action)
#    user = action.from_player ? $game.player1 : $game.player2
#    @file.write("#{user.name}(#{user.id}):\r\n#{action.escape}\r\n")
  end
  def self.load(filename)
    #TODO:效率优化
    file = open(filename)
    file.set_encoding "GBK", "UTF-8", :invalid => :replace, :undef => :replace
    result = self.new(file)
    contents = file.read
    contents =~ Player_Filter
    result.player1 = User.new($2.to_i, $1)
    contents =~ Opponent_Filter
    result.player2 = User.new($2.to_i, $1)
    result.actions = contents.split(Delimiter).collect do |action_str|
      action_str.chomp!
      action = Action.parse action_str
      Game_Event::Action.new(action, action_str)
    end
    $game.room = result.room = Room.new(0, "Replay", result.player1, result.player2)
    result
  end
  def get
    @actions.shift
  end
  def eof?
    @actions.empty?
  end
end
