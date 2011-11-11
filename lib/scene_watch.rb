#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================

class Scene_Watch < Scene_Duel
	def start
		Iduel::Event::OLIF.callback do |event|
			p event
		end
		Iduel::Event::NOL.callback do |event|
			p event
		end
		Iduel::Event::DOL.callback do |event|
			p event
		end
		Iduel::Event::RMIF.callback do |event|66
			p event
		end
		Iduel::Event::WMSG.callback do |event|
			p event
		end
	end
	def update
		
	end
end

