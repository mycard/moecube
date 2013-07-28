class ChatMessage
  attr_accessor :user, :message, :channel, :time

  def initialize(user, message, channel=:lobby, time=Time.now)
    @user = user
    @message = message
    @channel = channel
    @time = time
  end

  def name_visible?
    case channel
      when Symbol
        true
      when Room
        !channel.include?(user)
      when User
        false
    end
  end

  def name_color
    case user.affiliation
      when :owner
        [220,20,60]
      when :admin
        [148,43,226]
      else
        if user.id == :subject
          [128,128,128]
        else
          user == $game.user ? [0, 128, 0] : [0, 0, 255]
        end
    end
  end

  def message_color
    if user.id == :subject
      [128,128,128]
    elsif name_visible?
      [0, 0, 0]
    elsif user == $game.user or ($game.room and !$game.room.include?($user) and user == $game.room.player1)
      [0, 128, 0]
    else
      [255, 0, 0]
    end
  end

  def self.channel_name(channel)
    case channel
      when :lobby
        "#大厅"
      when Symbol
        "##{channel}"
      when Room
        "[#{channel.name}]"
      when User
        "@#{channel.name}"
      else
        channel
    end
  end

  def self.channel_color(channel)
    case channel
      when Symbol
        [0x34, 0x92, 0xEA]
      when Room
        [0xF2, 0x83, 0xC4]
      #[255,250,240]
      when User
        [0xFA, 0x27, 0x27]
      else
        [0, 0, 0]
    end
  end
end
