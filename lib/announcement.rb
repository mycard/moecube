class Announcement
  attr_accessor :title
  attr_accessor :url
  attr_accessor :time
  def initialize(title, url, time=nil)
    @title = title
    @url = url
    @time = time
  end
end
