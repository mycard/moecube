require_relative 'game'
require_relative 'user'
require_relative 'room'

require_relative 'ygocore/game'
$game = Ygocore.new
open('debug.txt', 'wb'){|f|f.write ARGV.first}

file = ARGV.first.dup.force_encoding("UTF-8")
file.force_encoding("GBK") unless file.valid_encoding?
file.encode!("UTF-8")

if ARGV.first[0, 9] == 'mycard://'
  file = URI.unescape file[9, file.size-9]
  uri = "http://" + URI.escape(file)
#elsif ARGV.first[0, 2] == '//'
#  file = URI.unescape URI.unescape ARGV.first[2, ARGV.first.size-2]
#  uri = "http://" + URI.escape(file)
else

  uri = file
end
case file
  when /^(.*\.yrp)$/i
    require 'open-uri'
    #fix File.basename
    $1 =~ /(.*)(?:\\|\/)(.*?\.yrp)/
    src = open(uri, 'rb') { |src| src.read }
    Dir.mkdir("replay") unless File.directory?("replay")
    open('replay/' + $2, 'wb') { |dest| dest.write src }
    Ygocore.replay('replay/' + $2, true)
  when /^(.*\.ydk)$/i
    require 'open-uri'
    #fix File.basename
    $1 =~ /(.*)(?:\\|\/)(.*?)\.ydk/
    src = open(uri, 'rb') { |src| src.read }
    Dir.mkdir('ygocore/deck') unless File.directory?("ygocore/deck")
    open('ygocore/deck/' + $2 + '.ydk', 'wb') { |dest| dest.write src }
    Ygocore.run_ygocore($2, true)
  when /^(.*)(\.txt|\.deck)$/i
    require_relative 'deck'
    d = $1
    deck = Deck.load($&)
    Dir.mkdir('ygocore/deck') unless File.directory?("ygocore/deck")
    d =~ /^(.*)(?:\\|\/)(.*?)$/
    open('ygocore/deck/' + $2 + '.ydk', 'w') do |dest|
      dest.puts("#main")
      deck.main.each { |card| dest.puts card.number }
      dest.puts("#extra")
      deck.extra.each { |card| dest.puts card.number }
      dest.puts("!side")
      deck.side.each { |card| dest.puts card.number }
    end
    Ygocore.run_ygocore($2, true)
  when /^(?:(.+?)(?:\:(.+?))?\@)?([\d\.]+)\:(\d+)(?:\/(.*))$/
    require 'uri'
	require_relative 'server'
    $game.user = User.new($1.to_sym, $1) if $1
    $game.password = $2 if $2
    room = Room.new(nil, $5.to_s)
	room.server = Server.new(nil, nil, $3, $4.to_i, !!$2)
    Ygocore.run_ygocore room, true
end