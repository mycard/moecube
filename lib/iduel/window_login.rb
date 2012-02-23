#encoding: UTF-8
class Window_Login
  def clicked
    case @index
    when :login
      Widget_Msgbox.new("iDuel", "正在登陆")
      $scene.draw #强制重绘一次，下面会阻塞
      $game = Iduel.new
      $config[$config['game']]['username'] = @username_inputbox.value
      $config[$config['game']]['password'] = @remember_password.checked? ? @password_inputbox.value : nil
      save_config
      $game.login(@username_inputbox.value, @password_inputbox.value)
    when :register
      require 'launchy'
      Launchy.open(Iduel::Register_Url)
    when :replay
      require 'tk'
      #由于Tk对话框点击取消的时候SDL会再识别一次点击，所以这里做一下处理，对两次间隔小于1s的点击忽略
      return if @replay_clicked and Time.now - @replay_clicked < 1
      file = Tk.getOpenFile
      if !file.empty?
        $game = Iduel.new
        $game.user = User.new(0)
        Widget_Msgbox.new("回放战报", "战报读取中...")
        $scene.draw
        $log.debug('iduel window_login'){'loading reply file'}
        $scene = Scene_Replay.new Replay.load file
      end
      @replay_clicked = Time.now
    end
  end
end
