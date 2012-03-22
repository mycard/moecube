require_relative 'widget_msgbox'
class Scene_Error < Scene
  def initialize(title="程序出错", text="似乎出现了一个bug，请到论坛反馈", &proc)
    @title = title
    @text = text
    @proc = proc || proc{$scene = Scene_Title.new}
    super()
  end
  def start
    Widget_Msgbox.new(@title, @text, :ok => "确定", &@proc)
  end
end
