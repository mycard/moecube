#encoding: UTF-8
class Window_Login
  def clicked
    case @index
    when :login
      $game = Iduel.new
      $game.login(@username_inputbox.value, @password_inputbox.value)
      Widget_Msgbox.new("iduel", "正在登陆")
    when :register
      require 'launchy'
      Launchy.open(Iduel::Register_Url)
    end
  end
end
