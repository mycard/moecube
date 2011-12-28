#encoding: UTF-8
class Window_Login
  def clicked
    case @index
    when :login
      Widget_Msgbox.new("iduel", "正在登陆")
      $scene.draw #强制重绘一次，下面会阻塞
      $game = Iduel.new
      $game.login(@username_inputbox.value, @password_inputbox.value)
    when :register
      require 'launchy'
      Launchy.open(Iduel::Register_Url)
    end
  end
end
