require_relative 'widget_msgbox'
class Scene_Error < Scene
  def start
    Widget_Msgbox.new("程序出错", "似乎出现了一个bug，请到论坛反馈", :ok => "确定"){$scene = Scene_Title.new}
  end
end
