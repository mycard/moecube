class Game_Event
  User_Filter = /\[(\d+),(.+?)(?:,(-1|0)|)\]/
  Room_Filter = /\[(\d+),(.+?),(wait|start)(#{User_Filter}+?)\]/
  #User_Filter = /<li>(：：：观战：|===决斗1=|===决斗2=)<font color="(?:blue|gray)">(.+?)(\(未认证\)|)<\/font>;<\/li>/
  #Room_Filter = /<div style="width:300px; height:150px; border:1px #ececec solid; float:left;padding:5px; margin:5px;">房间名称：(.+?)(<font color="d28311" title="竞技场模式">\[竞\]<\/font>|) (<font color=(?:\")?red(?:\")?>决斗已开始!<\/font>|<font color=(?:\")?blue(?:\")?>等待<\/font>)<font size="1">\(ID：(\d+)\)<\/font>#{User_Filter}+?<\/div>/
  class AllRooms < Game_Event
    def self.notify_send(title, msg)
      command = "notify-send -i graphics/system/icon.ico #{title} #{msg}"
      command = "start ruby/bin/#{command}".encode "GBK" if RUBY_PLATFORM["win"] || RUBY_PLATFORM["ming"]
      system(command)
      $log.info command
    end
    def self.parse(info)
      @rooms = []
      info.scan(Room_Filter) do |id, name, status, users|
        #p id, name, status, users, '------------'
        player1 = player2 = nil
        users.scan(User_Filter) do |player, name, certified|
          if name =~ /^<font color="(?:blue|gray)">(.+?)<\/font>$/
            name = $1
          end
          if certified == '0'
            certified = false
          elsif name =~ /^(.+?)\(未认证\)$/
            name = $1
            certified = false
          else
            certified = true
          end
          if player["1"]
            player1 = User.new(name.to_sym, name, certified)
          elsif player["2"]
            player2 = User.new(name.to_sym, name, certified)
          end
        end
        if player1 == $game.user or player2 == $game.user
          $game.room = Room.new(id.to_i, name)
        end
        
        if $game.room and id.to_i == $game.room.id and (($game.room.player1.nil? and player1 and player1 != $game.user) or ($game.room.player2.nil? and player2 and player2 != $game.user))
          @@join_se ||= Mixer::Wave.load("audio/se/join.ogg")
          Mixer.play_channel(-1,@@join_se,0)
          if $game.room.player1.nil? and player1 and player1 != $game.user
            player = player1
          elsif $game.room.player2.nil? and player2 and player2 != $game.user
            player = player2
          end
          notify_send("对手加入房间", "#{player.name}(#{player.id})")
        end        
        room = Room.new(id.to_i, name, player1, player2, false, [0,0,0])
        room.status = status.to_sym
        room.name =~ /^(P)?(M)?\#?(.*?)(?:<font color="d28311" title="竞技场模式">\[竞\]<\/font>)?$/
        room.name = $3
        room.pvp = !!$1
        room.match = !!$2
        if status == "wait"
          @rooms.unshift room
        else
          @rooms << room
        end
      end
      self.new @rooms
    end
  end
end