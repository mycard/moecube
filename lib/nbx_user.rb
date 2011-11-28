class NBX::User
  attr_accessor :name, :host
  @@all = []
  class <<self
    alias old_new new
    def new(name, host)
      user = @@all.find{|user| user.host == host }
      if user
        user.name = name
      else
        user = old_new(name, host)
        @@all << user
      end
      user
    end
  end
  def initialize(name, host)
    @name = name
    @host = host
  end
  def avatar(size)
    Surface.new(SWSURFACE, 1, 1, 32, 0,0,0,0)
  end
end