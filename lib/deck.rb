#encoding: UTF-8
#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================
require_relative 'card'
class Deck
	attr_accessor :main
	attr_accessor :side
	attr_accessor :extra
	attr_accessor :temp
  Key = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_="
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
    open(name) do |file|
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
  def self.ygopro_deck_to_url_param(file)
    card_usages = []
    side = false
    last_id = nil
    count = 0
    IO.readlines(file).each do |line|
      if line[0] == '#'
        next
      elsif line[0, 5] == '!side'
        card_usages.push({card_id: last_id, side: side, count: count}) if last_id
        side = true
        last_id = nil
      else
        card_id = line.to_i
        if card_id.zero?
          next
        else
          if card_id == last_id
            count += 1
          else
            card_usages.push({card_id: last_id, side: side, count: count}) if last_id
            last_id = card_id
            count = 1
          end
        end
      end
    end
    card_usages.push({card_id: last_id, side: side, count: count}) if last_id
    result = ""

    card_usages.each do |card_usage|
      c = (card_usage[:side] ? 1 : 0) << 29 | card_usage[:count] << 27 | card_usage[:card_id]
      4.downto(0) do |i|
        result << Key[(c >> i * 6) & 0x3F]
      end
    end
    require 'uri'
    "name=#{URI.escape(File.basename(file, ".ydk"), Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}&cards=#{result}"
  end
  #def self.decode(str)
  #  card_usages = []
  #  (0...str.length).step(5) do |i|
  #    decoded = 0
  #    str[i, 5].each do |char|
  #      decoded = (decoded << 6) + Key.index(char)
  #      side = decoded >> 29
  #      count = decoded >> 27 & 0x3
  #      card_id = decoded & 0x07FFFFFF
  #      card_usages.push(card_id: card_id, side: side, count: count)
  #    end
  #  end
  #end
end

