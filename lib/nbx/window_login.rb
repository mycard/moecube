#encoding: UTF-8
class Window_Login
  def initialize(*args)
    $game = NBX.new
    username = $config['username'] && !$config['username'].empty? ? $config['username'] : $_ENV['username']
    $game.login username
  end
end
