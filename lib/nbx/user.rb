class User
  def avatar(size=:small)
    Surface.load("#{ENV['TEMP']}/#{ENV['USERNAME']}.bmp") rescue Surface.new(SWSURFACE, 1, 1, 32, 0,0,0,0)
  end
end
