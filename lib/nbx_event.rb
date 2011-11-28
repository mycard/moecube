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
    when "Query"
    end.new($2, host)
  end
end
class NBX::Event::USERONLINE < NBX::Event
  attr_reader :user#, :session
  def initialize(info, host)
    
    username, need_reply = info.split(',')
    @user = NBX::User.new(username, host)
    @need_reply = need_reply == "1"
    p info, need_reply, @need_reply, @need_reply and @user != $nbx.user
    $nbx.send(@user, 'USERONLINE', $nbx.user.name) if @need_reply and @user != $nbx.user
  end
end