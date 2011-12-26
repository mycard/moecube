#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================

class Window_Info < Sprite
	def initialize(x, y, width, height, player, opponent)
		super( Image.new(width, height) ){|sprite|
			sprite.x = x
			sprite.y = y
		}
    self.contents[0].blit(player.avatar(:small))
    self.contents[0].blit(opponent.avatar(:small), width-48, 0)
    self.player_lp = 8000
    self.opponent_lp = 8000
		yield self if block_given?
	end
  def player_lp=(lp)
    lp = 8000 if lp > 8000
    lp = 0 if lp < 0
    width = (self.contents[0].width-48*2) * lp / 8000
    self.contents[0].fill_rect(Color::Red, 48,0, width,48/2)
    self.contents[0].fill_rect(Color::Red, 48+self.contents[0].width,0, self.contents[0].width - width,48/2)
  end
  def opponent_lp=(lp)
    lp = 8000 if lp > 8000
    lp = 0 if lp < 0
    width = (self.contents[0].width-48*2) * lp / 8000
    self.contents[0].fill_rect(Color::Red, 48,48/2, width,48/2)
    self.contents[0].fill_rect(Color::Red, 48+self.contents[0].width,48/2, self.contents[0].width - width,48/2)
  end
  def card=(card)
    card
  end
  
	#def player=(user)
	#	@user = user
	#	refresh
	#end
	def refresh

	end
end

#<Iduel::User:0x46b6438 @id="201629", @name="zh99997", @credit="Level-1 (\u603B\u7ECF\u9A8C:183)">