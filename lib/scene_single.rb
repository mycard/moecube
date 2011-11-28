#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================
=begin
class Scene_Single < Scene
  require_relative 'nbx'
  def start
    $server = NBX.new
    $server.login(ENV['username'])
    super
  end
  #def handle()
  def update
    while event = NBX::Event.poll
      handle_nbx(event)
    end
    super
  end
  def handle_nbx(event)
    case event
    when NBX::Event::USERONLINE
      p event.user
    end
  end
end
=end