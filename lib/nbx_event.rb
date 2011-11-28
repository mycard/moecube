#encoding: UTF-8
NBX::Event = Class.new #避开SDL::Event问题，所以没有用class NBX::Event::Event
class NBX::Event
  @queue = []
  def self.push(event)
    @queue << event
  end
  def self.poll
    @queue.shift
  end
  def self.parse(info, host)
    info =~ /^([A-Z]*)\|(.*)$/m
    case $1
    when "USERONLINE"
      NBX::Event::USERONLINE
    end.new($2, host)
  end
end
class NBX::Event::USERONLINE < NBX::Event
  attr_reader :user#, :session
  def initialize(info, host)
    @user = NBX::User.new(info, host)
  end
end