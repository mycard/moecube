class FPSTimer
  FPS_COUNT = 10

  attr_accessor :fps
  attr_reader :real_fps, :total_skip
  attr_reader :count_sleep
  # +fps+ is the number of frames per second that you want to keep,
  # +accurary+ is the accurary of sleep/SDL.delay in milisecond
  def initialize(fps = 60, accurary = 10, skip_limit = 15)
    @fps = fps
    @accurary = accurary / 1000.0
    @skip_limit = skip_limit
    reset
  end

  # reset timer, you should call just before starting loop
  def reset
    @old = get_ticks
    @skip = 0
    @real_fps = @fps
    @frame_count = 0
    @fps_old = @old
    @count_sleep = 0
    @total_skip = 0
  end

  # execute given block and wait
  def wait_frame
    now = get_ticks
    nxt = @old + (1.0/@fps)
    if nxt > now || @skip > @skip_limit
      yield
      @skip = 0
      wait(nxt)
      @old = nxt
    else
      @skip += 1
      @total_skip += 1
      @old = get_ticks
    end

    calc_real_fps
  end

  private
  def wait(nxt)
    #print "-"# 加了这货tk输入框不卡，原因不明=.=
    sleeptime = nxt-get_ticks
    sleep(sleeptime) if sleeptime > 0
  end

  def get_ticks
    SDL.get_ticks / 1000.0
  end

  def calc_real_fps
    @frame_count += 1
    if @frame_count >= FPS_COUNT
      @frame_count = 0
      now = get_ticks
      @real_fps = FPS_COUNT / (now - @fps_old)
      @fps_old = now
    end
  end
end
