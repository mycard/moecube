#encoding: UTF-8
#==Card Model
class Card
	require 'sqlite3'
	@db = SQLite3::Database.new( "data/data.sqlite" )
	@all = {}
  @diy = {}
	@count = @db.get_first_value("select COUNT(*) from YGODATA") rescue 0
	@db.results_as_hash = true
  PicPath = if RUBY_PLATFORM["win"] || RUBY_PLATFORM["ming"]
    require 'win32/registry'
    Win32::Registry::HKEY_CURRENT_USER.open('Software\OCGSOFT\Cards'){|reg|reg['Path']} rescue ''
  else
    '' #其他操作系统卡图存放位置标准尚未制定。
  end
  CardBack = Surface.load("graphics/field/card.jpg").display_format
  CardBack_Small = Surface.load("graphics/field/card_small.gif").display_format
	class << self
		def find(id, order_by=nil)
      case id
			when Integer
        @all[id] || old_new(@db.get_first_row("select * from YGODATA where id = #{id}"))
      when Symbol
				row = @db.get_first_row("select * from YGODATA where name = '#{id}'")
        if row
          @all[row['id'].to_i] || old_new(row)
        else
          @diy[id] ||= Card.new('id' => 0, 'number' => :"00000000", 'name' => id, 'card_type' => :通常怪兽, 'stats' => "", 'archettypes' => "", 'mediums' => "", 'lore' => "")
        end
      when Hash
        old_new(id)
      when nil
        Card::Unknown
      else
        sql = "select * from YGODATA where " << id
        sql << " order by #{order_by}" if order_by
        @db.execute(sql).collect {|row|@all[row['id'].to_i] || old_new(row)}
      end
    end
    def all
      if @all.size != @count
        sql = "select * from YGODATA where id not in (#{@all.keys.join(', ')})"
        @db.execute(sql).each{|row|old_new(row)}
      end
      @all
    end
    def cache
      @all
    end
    alias old_new new
    def new(id)
      find(id)
    end

    def load_from_ycff3(db = "E:/game/yu-gi-oh/YGODATA/YGODAT.mdb")
      require 'win32ole'
      conn = WIN32OLE.new('ADODB.Connection')
      conn.open("Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" + db + ";Jet OLEDB:Database Password=paradisefox@sohu.com" )
      records = WIN32OLE.new('ADODB.Recordset')
      records.open("select EFFECT from YGOEFFECT", conn)
      stats = records.GetRows.first
      stats.unshift nil
      records.close
      
      records = WIN32OLE.new('ADODB.Recordset')
      records.open("YGODATA", conn)

      sql = ""
      while !records.EOF
        sql << "INSERT INTO YGODATA VALUES(
          #{records.Fields.Item("CardID").value}, 
          '#{records.Fields.Item("CardPass").value}',
          '#{records.Fields.Item("SCCardName").value}',
          '#{records.Fields.Item("SCCardType").value}',
          '#{records.Fields.Item("SCDCardType").value.empty? ? "NULL" : records.Fields.Item("SCDCardType").value}',
          #{records.Fields.Item("CardATK").value || "NULL"}, 
          #{records.Fields.Item("CardDef").value || "NULL"}, 
          '#{records.Fields.Item("SCCardAttribute").value.empty? ? "NULL" : records.Fields.Item("SCCardAttribute").value}',
          '#{records.Fields.Item("SCCardRace").value.empty? ? "NULL" : records.Fields.Item("SCCardRace").value}',
          #{records.Fields.Item("CardStarNum").value || "NULL"},
          '#{records.Fields.Item("SCCardDepict").value}',
          #{case records.Fields.Item("ENCardBan").value; when "Normal"; 3; when "SubConfine"; 2; when "Confine"; 1; else; 0; end},
          '#{records.Fields.Item("CardEfficeType").value}',
          '#{records.Fields.Item("CardPhal").value.split(",").collect{|stat|stats[stat.to_i]}.join("\t")}',
          '#{records.Fields.Item("CardCamp").value.gsub("、", "\t")}',
          '#{records.Fields.Item("CardISTKEN").value.zero? ? "NULL" : ("1\t" * records.Fields.Item("CardISTKEN").value).chomp("\t")}'
        );"
        records.MoveNext
      end
      
      @db.execute('begin transaction')
      @db.execute('DROP TABLE "main"."YGODATA";') rescue nil
      @db.execute('CREATE TABLE "YGODATA" (
        "id"  INTEGER NOT NULL,
        "number"  TEXT NOT NULL,
        "name"  TEXT NOT NULL,
        "card_type"  TEXT NOT NULL,
        "monster_type"  TEXT,
        "atk"  INTEGER,
        "def"  INTEGER,
        "attribute"  TEXT,
        "type"  TEXT,
        "level"  INTEGER,
        "lore"  TEXT NOT NULL,
        "status"  INTEGER NOT NULL,
        "stats"  TEXT NOT NULL,
        "archettypes"  TEXT NOT NULL,
        "mediums"  TEXT NOT NULL,
        "tokens"  TEXT,
        PRIMARY KEY ("id")
      );')
      @db.execute_batch(sql)
      @db.execute('commit transaction')
      
      @count = @db.get_first_value("select COUNT(*) from YGODATA") #重建计数
      @all.clear #清空缓存
    end
  end
  attr_accessor :id
  attr_accessor :number
  attr_accessor :name
  attr_accessor :card_type
  attr_accessor :monster_type
  attr_accessor :atk
  attr_accessor :def
  attr_accessor :attribute
  attr_accessor :type
  attr_accessor :level
  attr_accessor :lore
  attr_accessor :status
  attr_accessor :stats
  attr_accessor :archettypes
  attr_accessor :mediums
  attr_accessor :tokens

  def initialize(hash)
    @id = hash['id'].to_i
    @number = hash['number'].to_sym
    @name = hash['name'].to_sym
    @card_type = hash['card_type'].to_sym
    @monster_type = hash["monster_type"] && hash["monster_type"].to_sym
    @atk = hash['atk'] && hash['atk'].to_i
    @def = hash['def'] && hash['def'].to_i
    @attribute = hash['attribute'] && hash['attribute'].to_sym
    @type = hash['type'] && hash['type'].to_sym
    @level = hash['level'] && hash['level'].to_i
    @lore = hash['lore']
    @status = hash['status'].to_i
    @stats = hash['stats'].split("\t").collect{|stat|stat.to_i}
    @archettypes = hash['archettypes'].split("\t").collect{|archettype|stat.to_sym}
    @mediums = hash['mediums'].split("\t").collect{|medium|medium.to_sym}
    @tokens = hash['tokens'] && hash['tokens'].split("\t").collect{|token|token.to_i}
    @token = hash['token']
    
    Card.cache[@id] = self
  end
  def create_image
    @image ||= Surface.load("graphics/field/card.jpg").display_format
  end
  def image
    @image ||= Surface.load("#{PicPath}/#{@id-1}.jpg").display_format rescue create_image
  end
  def image_small
    @image_small ||= image.transform_surface(0xFF000000,0,54.0/image.w, 81.0/image.h,Surface::TRANSFORM_SAFE).copy_rect(1, 1, 54, 81).display_format
  end
  def image_horizontal
    if @image_horizontal.nil?
      image_horizontal = image_small.transform_surface(0xFF000000,90,1,1,Surface::TRANSFORM_SAFE)
      @image_horizontal = image_horizontal.copy_rect(1, 1, 81, 54).display_format #SDL的bug，会多出1像素的黑边
      image_horizontal.destroy
    end
    @image_horizontal
  end
  def unknown?
    @id == 1
  end
  def monster?
    !@attribute.nil?
  end
  def trap?
    [:通常陷阱, :反击陷阱, :永续陷阱].include? card_type 
  end
  def spell?
    [:通常魔法, :速攻魔法, :装备魔法, :场地魔法, :仪式魔法, :永续魔法].include? card_type 
  end
  def extra?
    [:融合怪兽, :同调怪兽, :超量怪兽].include? card_type 
  end
  def token?
    @token
  end
  def inspect
    "[#{card_type}][#{name}]"
  end
  Unknown = Card.new('id' => 0, 'number' => :"00000000", 'name' => "", 'lore' => '', 'card_type' => :通常怪兽, 'stats' => "", 'archettypes' => "", 'mediums' => "")
  Unknown.instance_eval{@image = CardBack; @image_small = CardBack_Small}
end