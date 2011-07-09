#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================

class Scene_Single < Scene
	def start
		@background = Sprite.new
		@background.contents = Picture.new("title_0.jpg")
		@command_window = Window.new(600,250,300,500)
		@command_window.contents.color = [255,0,0]
		@command_window.contents.font.size = 32
		@command_window.contents.blt(0,32*0, "duel")
		@command_window.contents.blt(0,32*1, "single mode")
		@command_window.contents.blt(0,32*2, "deck edit")
		@command_window.contents.blt(0,32*3, "config")
		@command_window.contents.blt(0,32*4, "quit")
		$screen.make_magic_hooks(Screen::MousePressed => proc { |owner, event|
			if event.pos[0].between?(@command_window.x,  @command_window.x+ @command_window.width) && event.pos[1].between?(@command_window.y,  @command_window.y+ @command_window.height)
				$scene = case (event.pos[1] - @command_window.y) / 32
				when 0
					Scene_Login.new
				when 1
					Scene_Single.new
				when 2
					Scene_DeckEdit.new
				when 3
					Scene_Config.new
				when 4
					 nil
				end
			end
	  })


	end
	def update
		
	end
end

