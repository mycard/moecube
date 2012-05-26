require 'json'

require_relative 'game'
require_relative 'user'
require_relative 'room'

require_relative 'ygocore/game'
$game = Ygocore.new

args = JSON.parse ARGV.first[7, ARGV.first.size-7].unpack('m').first
$game.user = User.new(args["username"].to_sym, args["username"])
$game.password = args["password"]
$game.server = args['server_ip']
$game.port = args['server_port']
Ygocore.run_ygocore Room.new(0, args['room_name']), true