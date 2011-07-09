#encoding: UTF-8
#==============================================================================
# ■ Field
#------------------------------------------------------------------------------
# 　Field
#==============================================================================

#英汉对照表
# field 场地
# fieldcard 场地魔法卡
# spelltrap 魔法陷阱
# spell 魔法
# trap 陷阱
# graveyard 墓地
# deck 卡组
# extra 额外卡组
# removed 除外区
class Game_Field
  attr_accessor :lp
  attr_accessor :deck
  attr_accessor :extra
  attr_accessor :field
  attr_accessor :hand
  attr_accessor :graveyard
  attr_accessor :removed

	def initialize(deck = nil)
		@lp = 8000
		if deck
			@deck = deck.main
			@extra = deck.extra
    else
      @deck = Array.new(60, Card.find(nil))
      @extra = Array.new(15, Card.find(nil))
    end
    @field = []
    @hand = []
    @graveyard = []
    @removed = []
	end

end

__END__
=begin
	def field #场上
		player_field + opponent_field
	end
	def player_field #自己场上
		@player[0,11]
	end
	def opponent_field #对方场上
		@opponent[0,11]
	end
	def fieldcard #场地魔法卡
		@player[0] || @opponent[0]
	end
	def player_fieldcard #自己的场地魔法卡
		@player[0]
	end
	def opponent_fieldcard #对方的场地魔法卡
		@opponent[0]
	end
	def player_deck #自己的卡组
		@player[11, 60]
	end
	def player_extra #自己的额外卡组
		@player[61, 15]
	end
	def player_hand #自己的手卡
		@player[226, 60]
	end
	def opponent_hand #对方的手卡
		@opponent[161, 60]
	end
	def graveyard #墓地
		player_grave + opponent_grave
	end
	def player_grave #自己的墓地
		@player[11, 75]
	end
	def opponent_grave #对方的墓地
		@opponent[11, 75]
	end
	def removed #除外区
		@player + @opponent
	end
	def player_removed #自己的除外区
		@player[151, 75]
	end
	def opponent_removed #对方的除外区
		@opponent[151, 75]
	end
	def spelltraps #魔限
		player_spelltrap + opponent_spelltrap
	end
	def player_spelltraps #自己的魔限
		@player[1,5]
	end
	def opponent_spelltraps #对方的魔限
		@opponent[1,5]
	end
	def monsters #怪兽
		player_monsters + opponent_monsters
	end
	def player_monsters #自己的怪兽
		@player[6,5]
	end
	def opponent_monsters #对方的怪兽
		@opponent[6,5]
	end
=end