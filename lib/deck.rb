#encoding: UTF-8
#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================

class Deck
	attr_accessor :main
	attr_accessor :side
	attr_accessor :extra
	attr_accessor :temp
  #DeckPath = '/media/44CACC1DCACC0D5C/game/yu-gi-oh/deck'
  DeckPath = 'E:/game/yu-gi-oh/deck'
	def initialize(main, side=[], extra=[], temp=[])
		@main = main
		@side = side
		@extra = extra
		@temp = temp
	end
  def self.load(name)
    main = []
    side = []
    extra = []
    temp = []
    now = main
    open(File.expand_path(name, DeckPath)) do |file|
      file.set_encoding "GBK", "UTF-8", :invalid => :replace, :undef => :replace
      while line = file.readline.chomp!
        case line
        when /^\[(.+?)\](?:\#.*\#)?$/
          now << Card.find($1.to_sym)
        when "####"
          now = side
        when "===="
          now = extra
        when "$$$$"
          now = temp
        end
        break if file.eof?
      end
    end
    self.new(main, side, extra, temp)
  end
end

