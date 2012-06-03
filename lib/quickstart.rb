require_relative 'game'
require_relative 'user'
require_relative 'room'

require_relative 'ygocore/game'
$game = Ygocore.new
uri = URI.unescape URI.unescape ARGV.first[9, ARGV.first.size-9]
case uri
when /^(.*\.yrp)$/
  require 'open-uri'
  open("http://"+ URI.escape($1), 'rb') { |src|
    Dir.mkdir("replay") unless File.directory?("replay")
    open('replay/' + File.basename($1), 'wb'){|dest|
      dest.write src.read
    }
  }
  Ygocore.replay('replay/' + File.basename($1), true)
when /^(.*\.ydk)$/
  require 'open-uri'
  open("http://" + URI.escape($1), 'rb') { |src|
    Dir.mkdir('ygocore/deck') unless File.directory?("ygocore/deck")
    open('ygocore/deck/' + File.basename($1), 'wb'){|dest|
      dest.write src.read
    }
  }
  Ygocore.run_ygocore(File.basename($1, '.ydk'), true)
when /^(?:(.*)\:(.*)\@)?(.*)\:(\d+)\/(.*)$/
  require 'uri'
  $game.user = User.new($1.to_sym, $1) if $1
  $game.password = $2 if $2
  $game.server = $3
  $game.port = $4.to_i
  Ygocore.run_ygocore Room.new(0, $5), true
end