class Window_Deck < Window
  attr_reader :index

  def initialize
    @items = Dir.glob("ygocore/deck/*.ydk")[0, 10]
    @background = Surface.load(@items.size > 4 ? 'graphics/lobby/host.png' : 'graphics/system/msgbox.png').display_format
    super((1024-@background.w)/2, 230, @background.w, @background.h, 300)

    @items_button = Surface.load("graphics/system/deck_buttons.png")
    @items_buttons = {edit: "编辑", delete: "删除", export: "导出"}

    button_y = @height - 36
    @button = Surface.load("graphics/system/button.png")
    @buttons = {import: "导入", edit: "编辑", close: "关闭"}
    space = (@width - @buttons.size * @button.w / 3) / (@buttons.size + 1)
    @buttons_pos = {}
    @buttons.each_with_index do |button, index|
      @buttons_pos[button[0]] = [(space+@button.w/3)*index+space, button_y, @button.w/3, @button.h]
    end

    @font = TTF.open("fonts/wqy-microhei.ttc", 16)
    @title_color = [0xFF, 0xFF, 0xFF]
    @color = [0x04, 0x47, 0x7c]
    refresh
  end

  def refresh
    clear
    @font.draw_blended_utf8(@contents, "卡组编辑", (@width-@font.text_size("卡组编辑")[0])/2, 2, *@title_color)
    @items = Dir.glob("ygocore/deck/*.ydk")[0, 10]
    @background = Surface.load(@items.size > 4 ? 'graphics/lobby/host.png' : 'graphics/system/msgbox.png').display_format
    @height = @background.h
    @items.each_with_index do |deck, index|
      @font.draw_blended_utf8(@contents, File.basename(deck, ".ydk"), 16, 28+WLH*index, *@color)
    end
    @items.size.times do |index|
      @items_buttons.each_key do |key|
        draw_item([index, key], self.index==[index, key] ? 1 : 0)
      end
    end
    @buttons.each_key do |index|
      draw_item(index, self.index==index ? 1 : 0)
    end
  end

  def draw_item(index, status=0)
    x, y=item_rect(index)
    if index.is_a? Array
      Surface.blit(@items_button, status*@items_button.w/3, @items_buttons.keys.index(index[1])*@items_button.h/3, @items_button.w/3, @items_button.h/3, @contents, x, y)
    else
      Surface.blit(@button, @button.w/3*status, 0, @button.w/3, @button.h, @contents, x, y)
      text_size = @font.text_size(@buttons[index])
      @font.draw_blended_utf8(@contents, @buttons[index], x+(@button.w/3-text_size[0])/2, y+(@button.h-text_size[1])/2, 0xFF, 0xFF, 0xFF)
    end
  end

  def mousemoved(x, y)
    new_index = nil
    line = (y-@y-28)/WLH
    if line.between?(0, @items.size-1)
      i = (x - @x - (@width - @items_buttons.size * @items_button.w / 3)) / (@items_button.w/3)
      if i >= 0
        new_index = [line, @items_buttons.keys[i]]
      end
    else
      @buttons_pos.each_key do |index|
        if (x - @x).between?(@buttons_pos[index][0], @buttons_pos[index][0]+@buttons_pos[index][2]) and (y-@y).between?(@buttons_pos[index][1], @buttons_pos[index][1]+@buttons_pos[index][3])
          new_index = index
          break
        end
      end
    end
    self.index = new_index
  end

  def item_rect(index)
    if index.is_a? Array
      [
          @width - (@items_button.w/3) * (@items_buttons.keys.reverse.index(index[1])+1),
          28+WLH*index[0],
          @items_button.w/3,
          @items_button.h/3
      ]
    else
      @buttons_pos[index]
    end
  end

  def index=(index)
    return if index == @index

    if @index
      clear(*item_rect(@index))
      draw_item(@index, 0)
    end
    @index = index
    if @index
      clear(*item_rect(@index))
      draw_item(@index, 1)
    end
  end

  def clicked
    case self.index
      when :import
        import
        refresh
      when :edit
        Ygocore.run_ygocore(:deck)
      when :close
        destroy
      when Array
        case index[1]
          when :edit
            Ygocore.run_ygocore(@items[index[0]])
          when :delete
            require_relative 'widget_msgbox'
            Widget_Msgbox.new("删除卡组", "确定要删除卡组 #{File.basename(@items[index[0]], '.ydk')} 吗", buttons={ok: "确定", cancel: "取消"}) do |clicked|
              if clicked == :ok
                File.delete @items[index[0]]
                refresh
              end
            end
          when :export
            export
        end
    end
  end

  def import
    file = Dialog.get_open_file("导入卡组", "所有支持的卡组 (*.ydk;*.txt;*.deck)" => "*.ydk;*.txt;*.deck", "ygocore卡组 (*.ydk)" => "*.ydk", "OcgSoft卡组 (*.txt;*.deck)" => "*.txt;*.deck")
    if !file.empty?
      #fix for stdlib File.extname
      file =~ /(\.deck|\.txt|\.ydk)$/i
      extname = $1
      Dir.mkdir "ygocore/deck" unless File.directory?("ygocore/deck")
      open("ygocore/deck/#{File.basename(file, extname)+".ydk"}", 'w') do |dest|
        if file =~ /(\.deck|\.txt)$/i
          deck = Deck.load(file)
          dest.puts("#main")
          deck.main.each { |card| dest.puts card.number }
          dest.puts("#extra")
          deck.extra.each { |card| dest.puts card.number }
          dest.puts("!side")
          deck.side.each { |card| dest.puts card.number }
        else
          open(file) do |src|
            dest.write src.read
          end
        end
      end rescue ($log.error($!.inspect) { $!.backtrace.inspect }; Widget_Msgbox.new("导入卡组", "导入卡组失败", :ok => "确定"))
    end
  end

  def export
    require_relative 'dialog'
    file = Dialog.get_open_file("导出卡组", {"ygocore卡组 (*.ydk)" => "*.ydk", "OcgSoft卡组 (*.txt)" => "*.txt"}, [".ydk", ".txt"])
    if !file.empty?
      @items[index[0]]
      open(@items[index[0]]) do |src|
        if file =~ /.txt$/i
          main = []
          extra = []
          side = []
          now_side = false
          src.readlines.each do |line|
            line.chomp!
            if line[0, 1] == "#"
              next
            elsif line[0, 5] == "!side"
              now_side = true
            else
              card = Card.find("number = '#{line.rjust(8, '0')}'")[0]
              next if card.nil?
              if now_side
                side << card
              elsif card.extra?
                extra << card
              else
                main << card
              end
            end
          end
          open(file, 'w:GBK') do |dest|
            main.each { |card| dest.puts "[#{card.name}]##" }
            dest.puts "####"
            side.each { |card| dest.puts "[#{card.name}]##" }
            dest.puts "===="
            extra.each { |card| dest.puts "[#{card.name}]##" }
          end
        else
          open(file, 'w') do |dest|
            dest.write src.read
          end
        end
      end
    end
  end
end