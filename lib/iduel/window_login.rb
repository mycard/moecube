class Window_Login
  def clicked
    return if @last_clicked and Time.now - @last_clicked < 3 #防止重复点击
    case @index
    when :login
      Widget_Msgbox.new("iDuel", "正在登陆")
      $scene.draw #强制重绘一次，下面会阻塞
      $game = Iduel.new
      $config[$config['game']]['username'] = @username_inputbox.value
      $config[$config['game']]['password'] = @remember_password.checked? ? @password_inputbox.value : nil
      save_config
      $game.login(@username_inputbox.value, @password_inputbox.value)
      @last_clicked = Time.now
    when :register
      require 'launchy'
      Launchy.open(Iduel::Register_Url)
      @last_clicked = Time.now
    when :replay
      require_relative '../dialog'
      file = Dialog.get_open_file("播放战报", "所有支持的战报 (*.txt;*.htm)" => "*.txt;*.htm", "iDuel的html的战报 (*.htm)" => "*.htm", "文本战报 (*.txt)" => "*.txt")
      if !file.empty?
        $game = Iduel.new
        $game.user = User.new(0)
        Widget_Msgbox.new("回放战报", "战报读取中...")
        $scene.draw
        $log.info('iduel window_login'){'loading reply file'}
        $scene = Scene_Replay.new Replay.load file
      end
      @last_clicked = Time.now
    end
  end
end