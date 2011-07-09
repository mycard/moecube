#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================

class Window_Chat < Sprite
	def initialize(x, y, width, height)
		super( Image.new(width, height) ){|sprite|
			sprite.x = x
			sprite.y = y
			sprite.width = width
			sprite.height = height
			sprite.contents[0].font.size = 16
			sprite.contents[0].font.color = Color.new(0x031122)
			sprite.contents[0].font.smooth = true
			@font_bold = sprite.contents[0].font.dup
			@font_bold.bold = true
		}
		yield self if block_given?
	end
	def add(user, content)
		contents[0].blit(contents[0], 0, 0, 0, 24, contents[0].width, contents[0].height-16) #滚动条泥煤啊
		contents[0].fill_rect(Color::White, 0, contents[0].height-16, contents[0].width, 16)
		name = user.name+": "
		name_width = @font_bold.text_size(name)[0]
		contents[0].draw_text(name, 0, contents[0].height-16, @font_bold)
		contents[0].draw_text(content, name_width, contents[0].height-16)
	end
end

