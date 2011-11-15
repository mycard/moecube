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
    @field = Array.new(11)
    @hand = []
    @graveyard = []
    @removed = []
	end
end