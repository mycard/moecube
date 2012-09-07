class Window_Login
  def clicked
    return if @last_clicked and Time.now - @last_clicked < 3 #防止重复点击
    case @index
    when :login
      Widget_Msgbox.new("ygocore", "正在登录")
      $scene.draw #强制重绘一次，下面会阻塞
      $game = Ygocore.new
      $config[$config['game']]['username'] = @username_inputbox.value
      $config[$config['game']]['password'] = @remember_password.checked? ? @password_inputbox.value : nil
      Config.save
      $game.login(@username_inputbox.value, @password_inputbox.value)
      @last_clicked = Time.now
    when :register
      Ygocore.register
      @last_clicked = Time.now
    when :replay
      file = Dialog.get_open_file("播放录像", "ygocore录像 (*.yrp)" => "*.yrp")
      if !file.empty? and File.file? file
        Ygocore.replay file
      end
      @last_clicked = Time.now
    end
  end
end