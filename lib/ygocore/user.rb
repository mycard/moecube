#encoding: UTF-8
class User
  def initialize(id, name = "", certified = true)
    @id = id
    @name = name
    @certified = certified
  end
  def set(id, name = :keep, certified = :keep)
    @id = id unless id == :keep
    @name = name unless name == :keep
    @certified = certified unless certified == :keep
  end
  def color
    @certified ? [0,0,0] : [128,128,128]
  end
  def space
    Widget_Msgbox.new("查看资料", "功能未实现", :ok => "确定")
  end
end
