#encoding: UTF-8
#== Card Creater
#Author:: 忧雪の伤  (mailto:snow-heart@qq.com)
class Card
  Mark = Surface.load('graphics/cardcreater/mark.png').display_format
  Name_Font = TTF.open("graphics/cardcreater/经典细隶书繁.ttf", 13)
  Number_Font = TTF.open("graphics/cardcreater/arialbd.ttf", 7)
  Lore_Font = TTF.open("graphics/cardcreater/经典细隶书繁.ttf", 6)
  AtkDef_Font = TTF.open("graphics/cardcreater/Matrix.ttf", 8)
  #AtkDef_Value_Font = TTF.open("graphics/cardcreater/Lucida Sans Unicode.ttf", 12)
  AtkDef_Value_Font = TTF.open("graphics/cardcreater/Lucida Sans Unicode.ttf", 8)
  def create_image
    #载入背景图
    result = if monster?
      Surface.load "graphics/cardcreater/back/#{card_type}/#{attribute} #{level}.jpg"
    else 
      Surface.load "graphics/cardcreater/back/#{card_type}.jpg"
    end
    
    #描绘标记
    result.put Mark, 148, 218
    
    #描绘卡名
    Name_Font.draw_blended_utf8(result, name.to_s, 15, 10, *name_color)

    #描绘编号
    Number_Font.draw_blended_utf8(result, number.to_s, 6, 219, *number_color) unless diy?
    
    #描绘效果
    line_height = 6
    
    width = 0
    line = 0
    str = ""
    
    lore.each_char do |char|
      char_width = Lore_Font.text_size(char)[0]
      if char_width + width > 124
        break if line >= 4
        Lore_Font.draw_blended_utf8(result, str, 14, 111 + (monster? ? 68 : 62)+line*line_height, *number_color)
        width = 0
        line += 1
        str.clear
      else
        width += char_width
        str << char
      end
    end
    Lore_Font.draw_blended_utf8(result, str, 14, 111+(monster? ? 68 : 62)+line*line_height, *number_color) unless str.empty?   
    
    
    if monster?
      #描绘种族
      if card_type.equal? :通常怪兽
        if monster_type.equal? :调整
          str = "【#{type}族·调整】" 
        else 
          str = "【#{type}族】"
        end
      elsif [:灵魂, :同盟, :卡通, :二重, :调整].include? monster_type
        str = "【#{type}族·#{monster_type}】"
      else
        str = "【#{type}族·#{card_type.to_s.sub(/怪兽/, '')}】"
      end
      Lore_Font.style = TTF::STYLE_BOLD
      Lore_Font.draw_blended_utf8(result, str, 11, 173, *number_color)
      Lore_Font.style = TTF::STYLE_NORMAL
      
      #描绘攻防  
      atkdef = 'ATK/          DEF/        '
      #atkdef = "ATK/#{atk}    DEF/#{self.def}    "
      x = 146-AtkDef_Font.text_size(atkdef)[0]
      AtkDef_Font.draw_blended_utf8(result, atkdef, x, 209, *number_color)

      #atkdef_value = "#{atk}          #{self.def}"
      atkdef_value = "#{atk}       #{self.def}"
      x = 146-AtkDef_Value_Font.text_size(atkdef_value)[0]
      AtkDef_Value_Font.draw_blended_utf8(result, atkdef_value, x, 207, *number_color)
    end
    
    result
  end
  def name_color
    if [:通常怪兽, :效果怪兽, :融合怪兽, :仪式怪兽, :同调怪兽].include? card_type
      [0, 0, 0]
    else
      [255, 255, 255]
    end
  end
  def number_color
    if [:超量怪兽].include? card_type
      [255, 255, 255]
    else
      [0, 0, 0]
    end
  end
end

=begin
#以下忧雪の伤的原版，for RPG Maker VX
class String
  
  # Temp
  def each_char
    scan(/./).each {|char| yield char }
  end
  alias each each_char
  include Enumerable
  
end

class Card
  
  # Default
  
  attr_accessor :id 
  attr_accessor :number
  attr_accessor :name
  attr_accessor :card_type
  attr_accessor :monster_type
  attr_accessor :atk 
  attr_accessor :def
  attr_accessor :attribute
  attr_accessor :type
  attr_accessor :level
  attr_accessor :lore
  attr_accessor :status
  attr_accessor :stats 
  attr_accessor :archettypes
  attr_accessor :mediums
  attr_accessor :tokens
  
  def image

    # Result Create
    result = Bitmap.new 160, 230
    
    # Mark & Image Create
    mark = Bitmap.new 'Mark'
    image = Bitmap.new "Image/#{id}"
    
    # Back Create
    if monster?
      back = Bitmap.new "Back/#{card_type}/#{attribute} #{level}"
    else 
      back = Bitmap.new "Back/#{card_type}"
    end
    
    # Blt All
    result.blt 0, 0, back, back.rect
    result.blt 148, 218, mark, mark.rect
    result.blt 21, 46, image, image.rect
    
    # Name Create
    result.font.size = 13
    result.font.name = '经典细隶书繁'
    if [:通常怪兽, :效果怪兽, :融合怪兽, :仪式怪兽, :同调怪兽
      ].include? card_type
      result.font.color.set 0, 0, 0
    else
      result.font.color.set 255, 255, 255
    end
    src_bitmap = Bitmap.new [result.text_size(name).width, 108].max, 18
    src_bitmap.font = result.font
    src_bitmap.draw_text src_bitmap.rect, name
    result.stretch_blt Rect.new(15, 10, 108, 18), src_bitmap, src_bitmap.rect
    
    # Number Create
    result.font.size = 7    
    result.font.bold = true
    result.font.name = 'Arial'
    if card_type.equal? :XYZ怪兽
      result.font.color.set (255, 255, 255)
    else
      result.font.color.set (0, 0, 0) 
    end
    result.draw_text 6, 219, 160, 7, number
    result.font.bold = false
    
    # Lore Create
    src_bitmap = Bitmap.new 1280, 800
    src_bitmap.font.size = 6
    src_bitmap.font.color.set 0, 0, 0
    src_bitmap.font.name = '经典细隶书繁'
    height = src_bitmap.text_size(lore).height
    inject = lore.inject([0, 0, 0]) {|array, char|
      text_size = src_bitmap.text_size char
      args = array[0], array[1], text_size.width, text_size.height, char
      src_bitmap.draw_text *args
      if array[0] < 124
        [array[0] + text_size.width, array[1], array[2]]
      else
        [0, array[1] + height, array[2] + 1]
      end
    }
    src_rect = Rect.new 0, 0, 133, (inject[2] + 1) * height
    dest_rect = Rect.new 14, 111 + (monster? ? 68 : 62), 0, 0
    dest_rect.width = [inject[1], 133].max
    dest_rect.height = [(inject[2] + 1) * height, 30].min
    result.stretch_blt dest_rect, src_bitmap, src_rect
    
    if monster?
      
      # Type Create
      result.font = src_bitmap.font
      if card_type.equal? :通常怪兽
        if monster_type.equal? :调整
          string = "【#{type}族·调整】" 
        else 
          string = "【#{type}族】"
        end
      elsif [:灵魂, :同盟, :卡通, :二重, :调整].include? monster_type
        string = "【#{type}族·#{monster_type}】"
      else
        string = "【#{type}族·#{card_type.to_s.sub(/怪兽/, '')}】"
      end
      result.font.bold = true
      result.draw_text 11, 173, 160, 6, string
      result.font.bold = false
      
      # ATK & DEF Create
      result.font.size = 8
      result.font.name = 'Matrix'
      result.draw_text -14, 209, 160, 8, 'ATK/          DEF/        ', 2
      result.font.size = 12
      result.font.name = 'Lucida Sans Unicode'
      result.draw_text -14, 207, 160, 12, "#{atk}          #{self.def}", 2
    
    end
      
    # Return
    result
    
  end
  def monster? 
    
    # Temp
    [:通常怪兽, :效果怪兽, :融合怪兽, :仪式怪兽, :同调怪兽, :XYZ怪兽
      ].include? card_type
  
  end
  def spell?
    
    # Temp
    !monster?
    
  end
  def trap?
    
    # Temp
    !monster?
    
  end
end
=end