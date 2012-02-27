#encoding: UTF-8
class Replay
  User_Filter = /(.+?)(?:\((\d+)\))?(?:\(\d+:\d+:\d+\))?(?::|：) */
  Delimiter = /^#{User_Filter}\n ?/
  Player_Filter = /#{Delimiter}\[\d+\] ◎→/
  Opponent_Filter =/#{Delimiter}\[\d+\] ●→/
  HTML_Player_Filter = /<font color=blue><strong>#{User_Filter}<\/strong>/
  HTML_Opponent_Filter = /<font color=red><strong>#{User_Filter}<\/strong>/
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
    contents = file.read.strip
    if contents['<td width="75%" valign="top">']
      result.player1 = User.new($2.to_i, $1) if contents =~ HTML_Player_Filter
      result.player2 = User.new($2.to_i, $1) if contents =~ HTML_Opponent_Filter
      from_players =  contents.scan(Regexp.union(HTML_Player_Filter, HTML_Opponent_Filter)).collect{|matched|matched[0] ? true : false} #匹配player成功matched前两位有值，opponent成功后两位有值，["尸体", "100015", nil, nil], il, nil], [nil, nil, "游戏的徒弟", "288436"]
      #去除HTML标签
      contents.gsub!(/<.*?>/,'')
      #处理HTML转义字符
      require 'cgi'
      contents = CGI.unescape_html(contents)
    else
      result.player1 = User.new($2 ? $2.to_i : :player, $1) if contents =~ Player_Filter
      result.player2 = User.new($2 ? $2.to_i : :opponent, $1) if contents =~ Opponent_Filter
      from_players = contents.scan(Delimiter).collect do |matched|
        id = matched[1].to_i
        name = matched[0]
        if result.player1 and result.player1.id == id
          true
        elsif result.player2 and result.player2.id == id
          false
        elsif result.player1.nil?
          result.player1 = User.new(id, name)
          true
        elsif result.player2.nil?
          result.player2 = User.new(id, name)
          false
        else
          #无法匹配玩家，一般是观战消息..
          false
        end
      end
    end
    result.player1 ||= User.new(0, "我")
    result.player2 ||= User.new(1, "对手")
    lines = contents.split(Delimiter)
    lines.shift #split后，在第一个操作之前会多出一个空白元素
    if from_players.empty?
      Game_Event.push Game_Event::Error.new("播放战报", "战报无法识别")
      return []
    end
    lines = lines.each_slice(lines.size/from_players.size).collect{|a|a.last.strip}
    from_players = from_players.to_enum
    result.actions = lines.collect do |action_str|
      action = Action.parse action_str
      action.from_player = from_players.next
      Game_Event::Action.new(action, action_str)
    end
    $game.room = result.room = Room.new(0, "Replay", result.player1, result.player2)
    result
  end
  def self.html_decode(text)
    text.gsub(Regexp.new(HTML_Replacement.keys.collect{|key|Regexp.escape key}.join('|')), HTML_Replacement)
  end
  def get
    @actions.shift
  end
  def eof?
    @actions.empty?
  end
end
