#encoding: UTF-8
#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================

class Scene_Deck < Scene
	def start
		@deck_window = Window.new(600,0,400,800)
		loaddeck
		@deck_window.contents.blt(@deck.main.first.pic, 200, 0)
		@deck.main.each_with_index do |card, index|
			@deck_window.contents.draw_text(0, index*24, card.name)
			
		end
    super
	end
	def loaddeck(file='/media/本地磁盘/zh99998/yu-gi-oh/token.txt')
		src = IO.read(file)
		src.force_encoding "GBK"
		src.encode! 'UTF-8'
		cards = {:main => [], :side => [], :extra => [], :temp => []}
		now = :main
		src.each_line do |line|
			if line =~ /\[(.+)\]##(.*)\r\n/
				cards[now] << Card.find($1.to_sym)
			elsif line['####']
				now = :side
			elsif line['====']
				now = :extra
			elsif line['$$$$']
				now = :temp
			end
		end
		@deck = Deck.new(cards[:main], cards[:side], cards[:extra], cards[:temp])
	end
	def update
		
	end
end

