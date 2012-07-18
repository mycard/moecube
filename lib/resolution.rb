module Resolution
  module_function

  def all
    [
        [1024, 768],
        [1024, 640]
    ]
  end

  def system
    return [1024, 768]
    if Windows
      require 'win32api'
      get_system_metrics = Win32API.new "User32.dll", "GetSystemMetrics", ["L"], "L"
      [get_system_metrics.call(0), get_system_metrics.call(1)]
    else
      `xrandr`.scan(/current (\d+) x (\d+)/).flatten.collect { |n| n.to_i }
    end
  end

  def default
    system_resolution = self.system
    all.each do |width, height|
      #p [width, height, system_resolution[0], system_resolution[1], (system_resolution[0] < width and system_resolution[1] < height)]
      return [width, height] if system_resolution[0] > width and system_resolution[1] > height
    end
    all.last
  end
end