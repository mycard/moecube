#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================

class Sprite_Card < Sprite
  Card_Witdh = 54
  Card_Height = 81
	def initialize(card, x, y)
		super( card.pic ){|sprite|
			sprite.x = x
			sprite.y = y
			#sprite.contents[0].font.size = 8
			#sprite.contents[0].font.color = Color::White
      sprite.zoom_x = Card_Witdh.to_f / sprite.contents[0].width
      sprite.zoom_y = Card_Height.to_f / sprite.contents[0].height
			#sprite.contents[0].font.smooth = true
			#@font_bold = sprite.contents[0].font.dup
			#@font_bold.bold = true
		}
		yield self if block_given?
	end
end

